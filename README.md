# jq docker action

This action opens a container with jq as a valid command 

## Inputs

### `cmd`

**Required** The bash command(s) you wish to run

## Outputs

### `stdout`

the standard output from the bash command

### `stderr`

the standard error from the bash command

### `exit_code`

the standard error from the bash command

## Example usage

uses: actions/jq-action@v1
with:
  cmd: >
    echo '{
        foo: "bar"
    }' | 
    jq '.foo'

# Developing
jq-action uses husky to manage and setup git hooks. 
1) `npm i`
1) `npm run postinstall`
1) `npm run build`
1) `npm run test`
1) `INPUT_CMD="jq -nc '{foo:\"bar\"}|keys' " npm run shell`




