
~/.claude/skills/agent-team/
├── SKILL.md              # Claude reads this, handles everything
├── REFERENCE.md          # API lookup
└── scripts/
    ├── watch-tasks.sh    # monitoring pane: polls task JSON
    ├── watch-inbox.sh    # monitoring pane: tails leader inbox
    └── watch-team.sh     # monitoring pane: polls team config


install:

tar xzf agent-team-skill.tar.gz -C ~/.claude/skills/
chmod +x ~/.claude/skills/agent-team/scripts/*.sh


use:

zellij                                    # start zellij
claude --dangerously-skip-permissions     # start claude
# talk to claude → skill activates → it opens the monitor tab itself



