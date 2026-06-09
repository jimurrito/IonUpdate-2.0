# Claude documentation rules

- your goal is to write documentation for the given repo.
- 2 key things that need to be documented:
  - README.md
  - doc text for functions and modules (dependant on language used)

## README.md structure

List is formated in the order I want the segments placed.

- Title
- Badges:
  - Language(s)
  - License
- simple description
- Create TOC
- requirements/dependancies (where applicable)
- How to use with an psuedo code examples containing place holder values
- Real example
- provide nix flake data below any other higher level code examples (where applicable)
- mention a link to the repo license at bottom

### Lang specific README.md rules

#### Nix

- if the repo contains a `flake.nix` file, please give a simple example of how to use it.
- Include the input and then the output where it can be used.
- Typically you can use the nixosConfigurations.test-vm as an example of implementing the derevation
- Include a table on the readme with a schema for the options offered by the `flake.nix` file.
- If the nixosconfigurations.test-vm is in the flake.nix file, do not document that on the readme. that is for my testing.

#### Powershell

- mention how to import the module from file
- package maybe available on nuget via install-module, but this is less likely. Please ask to confirm.
- example of how to use it at a high level with example data
- If the primary role of the repo is a module, create a table with the function names and thier descriptions.
- If the primary role of the repo is a script, create examples of how to use the script. Do not document the lower level functions used.

#### Unmapped langs

- best effort based on common documentation standards the what i commonly ask for in the above langs.


## Doc module/script doc text

These are documents that will be inline with the code itself.
the goal of this is for the docs to be picked up by a language server linter or in powershell's case get-help

As of now, only powershell needs this kind of treatment.

- Modules (.psm1)
  - Document functions using powershell document syntax. 
  - Ensure to explain all params and give examples where applicable.
- Scripts (.ps1)
  - Create the doc syntax at the top of the script. Do not add documentation to any other code in scripts.