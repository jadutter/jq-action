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

uses: actions/jq@v1
with:
  cmd: |
    echo '{
        foo: "bar"
    }' | 
    jq '.foo'