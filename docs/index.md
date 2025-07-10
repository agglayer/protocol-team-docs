# Team protocol documentation page

- [Documentation link](https://expert-journey-9jzpgrg.pages.github.io/)
- kanban board to track `Protocol` team tasks

## Team members
- Carlos
- Laia
- Jesús
- Ignasi

## Repositories and owners
- [zkevm-rom](https://github.com/0xPolygonHermez/zkevm-rom)
- [zkevm-contracts](https://github.com/0xPolygonHermez/zkevm-contracts)
- [zkevm-commonjs](https://github.com/0xPolygonHermez/zkevm-commonjs)
- [zkevm-testvectors](https://github.com/0xPolygonHermez/zkevm-testvectors)
- [zkevm-proverjs](https://github.com/0xPolygonHermez/zkevm-proverjs)
- [ethereumjs-monorepo](https://github.com/hermeznetwork/ethereumjs-monorepo)
- [fork ethereum-tests](https://github.com/0xPolygonHermez/ethereum-tests)

## Notion
- [Protocol team landing page](https://www.notion.so/polygontechnology/Protocol-team-b3ee0712a65b4558910bea2ed1aecf03)

## Documentation
Documentation is available with `mkdocs`

### How to install and run
````
pip install mkdocs
pip install -r requirements.txt
mkdocs serve
````

A bash script has been added to easily import hackmd files to the mkdocs page:
````
sh addHackMD.sh
````

Just follow the cli instructions, to add more paths where to store files, you should create the folders manually directly inside the `/docs` path.
Adding files manually is also supported