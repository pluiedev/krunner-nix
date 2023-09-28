use std::borrow::Cow;
use std::collections::HashMap;
use std::fmt::Write;

use anyhow::{Context, Result};
use async_trait::async_trait;
use krunner::{AsyncRunnerExt, Match, MatchType};
use probly_search::score::zero_to_one;
use probly_search::{Index, QueryResult};
use serde::Deserialize;
use tokio::process::Command;

#[derive(Debug, Copy, Clone, Eq, PartialEq, krunner::Action)]
enum Action {
	#[action(id = "run", title = "Run Nix program", icon = "system-run-symbolic")]
	Run,
	#[action(
		id = "shell",
		title = "Spawn a new shell with Nix program",
		icon = "new-command-alarm"
	)]
	Shell,
}

#[derive(Debug, Clone, Eq, PartialEq, Deserialize)]
struct Program {
	#[serde(default = "String::new")]
	id: String,
	description: String,
	pname: String,
	version: String,
}
impl Program {
	fn indexable_fields(&self) -> Vec<&str> {
		vec![
			self.id.as_str(),
			self.description.as_str(),
			self.pname.as_str(),
		]
	}
}

struct Runner {
	programs: Vec<Program>,
	index: Index<usize>,
}
impl Runner {
	async fn new() -> Result<Self> {
		let mut index = Index::new(1);

		// TODO: add support for different flakes (i.e. blender-bin)
		let output = Command::new("nix")
			.args([
				"search",
				"nixpkgs",
				"--json",
				"--extra-experimental-features",
				"nix-command",
			])
			.output()
			.await
			.context("could not get nix index")?
			.stdout;

		let progs: HashMap<String, Program> =
			serde_json::from_slice(&output).context("got malformed JSON from Nix")?;

		let programs: Vec<_> = progs
			.into_iter()
			.enumerate()
			.map(|(i, (id, mut prog))| {
				prog.id = id.splitn(3, '.').nth(2).unwrap().to_string();

				index.add_document(&[Program::indexable_fields], tokenizer, i, &prog);
				prog
			})
			.collect();

		println!("Loaded {} programs", programs.len());

		Ok(Self { programs, index })
	}

	fn to_match(
		&self,
		query: &str,
		QueryResult { key, score }: QueryResult<usize>,
	) -> Match<Action> {
		let Program {
			id,
			description,
			version,
			..
		} = &self.programs[key];

		let mut title = format!("Nix: {id}");
		if !version.is_empty() {
			write!(title, " ({version})").unwrap();
		}

		Match {
			id: id.to_string(),
			title,
			subtitle: description.clone().into(),
			icon: "nix-snowflake".to_owned().into(),

			ty: if query.trim().eq_ignore_ascii_case(id) {
				MatchType::ExactMatch
			} else {
				MatchType::PossibleMatch
			},

			actions: vec![Action::Run, Action::Shell],
			relevance: score,
			..Match::default()
		}
	}
}

#[async_trait]
impl krunner::AsyncRunner for Runner {
	type Action = Action;
	type Err = String;

	async fn matches(&mut self, query: String) -> Result<Vec<Match<Self::Action>>, Self::Err> {
		let matches: Vec<_> = self
			.index
			.query(&query, &mut zero_to_one::new(), tokenizer, &[])
			.into_iter()
			.map(|q| self.to_match(&query, q))
			.take(10)
			.collect();
		Ok(matches)
	}

	async fn run(
		&mut self,
		match_id: String,
		action: Option<Self::Action>,
	) -> Result<(), Self::Err> {
		let cmd = match action {
			Some(Action::Shell) => "shell",
			None | Some(Action::Run) => "run",
		};

		Command::new("konsole")
			.args([
				"-e",
				"nix",
				cmd,
				&format!("nixpkgs#{match_id}"),
				"--extra-experimental-features",
				"nix-command",
			])
			.spawn()
			.unwrap();
		Ok(())
	}
}

fn tokenizer(s: &str) -> Vec<Cow<str>> {
	s.split(' ').map(Cow::from).collect()
}

#[tokio::main]
async fn main() -> Result<()> {
	Runner::new()
		.await?
		.start(env!("DBUS_SERVICE"), env!("DBUS_PATH"))
		.await?;
	Ok(())
}
