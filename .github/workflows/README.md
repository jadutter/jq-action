# Introduction

I made this repo because I did not find a [GitHub action](https://github.com/marketplace?type=actions) to test jq modules that I liked. 
This document is to help with understanding the workflows. 

# The Workflows 

## `test-all.yml` 

This workflow is:

1. Checking the syntax we use to save results from within one step are accessible in another

1. Checking whether the environment in the docker container has all that we expect

1. Checking whether we can use the `HEAD` for the current branch as a GitHub action

## `test-develop.yml` 

This workflow is supposed to be testing if the `HEAD` for the current branch can be used as a GitHub action for some repository that would intend to use the action.

This involves mocking being used in another repository, by including the `tests` directory in this repo, and assuming the files and values would be accessible to the action.

## `test-release.yml` 

This workflow is for checking that `jadutter/jq-action@release` is light weight (it doesn't have things we added specifically for testing).

Ideally, we would use a [docker multistage image](https://docs.docker.com/build/building/multi-stage/), like so

```
# Release Image =============================================================
FROM alpine:latest as release_image

COPY entrypoint.sh /entrypoint.sh

RUN apk add jq bash 

ENTRYPOINT ["/entrypoint.sh"]

# Develop Image =============================================================
FROM release_image as develop_image

COPY tests /tests

RUN apk add git

ENTRYPOINT ["/entrypoint.sh"]
```

but I don't see a way to have a github workflow target a specific docker build. It can target a specific directory, but that would require some re-organizing files, and reorganizing may break GitHub's ability to use a Dockerfile at the root level. 

Example command to stop at a specific image. 
```
docker build -f Dockerfile --target release_image .
```

(I don't think I'm explaining this well; but hopefully these are just notes for myself)


# Syntax Notes

## Heredoc

Write 6 characters to `/tmp/output.txt` (the numbers separated by newline characters, plus a newline at the end caused by using the heredoc).

```bash
v='1
2
3'
cat << EOF >/tmp/output.txt
$v
EOF

# returns 6
cat /tmp/output.txt | wc -m
``` 

Putting the delimiter `EOF` inside single quotes prevents variable expansion inside the heredoc. So we write the literal two characters `$v`, plus a newline at the end caused by using the heredoc.

```bash
v='1
2
3'
cat << 'EOF' >/tmp/output.txt
$v
EOF

# returns 3
cat /tmp/output.txt | wc -m
``` 

## YAML multiline strings

An interactive demo can be found at [yaml-multiline.info](https://yaml-multiline.info/).

### Block Style Indicator

Affects how newlines between content are treated.

#### Folded

`>` 

The text can be multiple lines, but will be treated as a single line (except newlines containing no other text, which will be treated as a newline).

```yaml
example: >
  Several lines of text,
  with some "quotes" of various 'types',
  and also a blank line:
  
  and some text with
    extra indentation
  on the next line,
  plus another line at the end.
  
  
```

The value of `example` is 

```
Several lines of text, with some "quotes" of various 'types', and also a blank line:
and some text with
  extra indentation
on the next line, plus another line at the end.
```

#### Literal

`|` 

The text can be multiple lines, keeping literal newlines.

```yaml
example: |
  Several lines of text,
  with some "quotes" of various 'types',
  and also a blank line:
  
  and some text with
    extra indentation
  on the next line,
  plus another line at the end.
  
  
```

The value of `example` is 

```
Several lines of text,
with some "quotes" of various 'types',
and also a blank line:

and some text with
  extra indentation
on the next line,
plus another line at the end.
```

### Block Chomping Indicator

Affects how newlines at the end of the content are treated.

Note, we're removing the single quotes from the example, and using a `bash` snippet so we can use `printf` to convey what the literal value is.

### Clip

If no modifiers are used, then there is a single newline after the content ends.

```yaml
example: |
  Several lines of text,
  with some "quotes" of various types,
  and also a blank line:
  
  and some text with
    extra indentation
  on the next line,
  plus another line at the end.
  
  
```

The value of `example` is

```bash
printf 'Several lines of text,
with some "quotes" of various types,
and also a blank line:

and some text with
  extra indentation
on the next line,
plus another line at the end.
'
```

### Strip

`-`

With this modifier, all newlines are stripped from the end of the string.

```yaml
example: |-
  Several lines of text,
  with some "quotes" of various types,
  and also a blank line:
  
  and some text with
    extra indentation
  on the next line,
  plus another line at the end.
  
  
```

The value of `example` is

```bash
printf 'Several lines of text,
with some "quotes" of various types,
and also a blank line:

and some text with
  extra indentation
on the next line,
plus another line at the end.'
```

### Keep

`+`

With this modifier, all newlines are kept at the end of the string.

```yaml
example: |+
  Several lines of text,
  with some "quotes" of various types,
  and also a blank line:
  
  and some text with
    extra indentation
  on the next line,
  plus another line at the end.
  
  
```

The value of `example` is

```bash
printf 'Several lines of text,
with some "quotes" of various types,
and also a blank line:

and some text with
  extra indentation
on the next line,
plus another line at the end.

'
```

## Github Multiline Output

```yaml
steps:
  - name: Set 
    id: step_one
    run: |
      {
        echo 'JSON_RESPONSE<<EOF'
        curl -k -X POST https://reqbin.com/echo/post/json -H 'Content-Type: application/json' -d '{"foo":"bar"}'
        echo EOF
      } >> "$GITHUB_OUTPUT"

  - name: Get 
    id: step_two
    run: |
      echo "${{ steps.step_one.outputs.JSON_RESPONSE }}"
```

In this example, 

```yaml
# Different EOF delimiters were used to make it clearer which the explaination below is referencing
steps:
  - name: Set 
    id: step_one
    run: |
      (
      cat << 'EOF_GITHUB_OUTPUT' >> $GITHUB_OUTPUT
      json<<EOF
      {
        "cost": "$1.99"
      }
      EOF
      EOF_GITHUB_OUTPUT
      ); 

  - name: Get 
    id: step_two
    run: |
      (
      cat << 'EOF_EXPECTED' >>/tmp/expected.txt
      {
        "cost": "$1.99"
      }
      EOF_EXPECTED
      );

      (
      cat << 'EOF_RECEIVED' >>/tmp/received.txt
      ${{ steps.step_one.outputs.json }}
      EOF_RECEIVED
      );

      git diff --no-index /tmp/expected.txt /tmp/received.txt;
```

`step_one` appends to the `GITHUB_OUTPUT` file the content

```
json<<EOF
{
  "cost": "$1.99"
}
EOF
```

Note, in this step, `EOF_GITHUB_OUTPUT` is in single quotes to prevent variable expansion on `$1` within the content.


`step_two` writes two files and compares them. 

Likewise, `step_two` uses single quotes on `EOF_EXPECTED` and `EOF_RECEIVED` to prevent variable expansion on `$1` in the content it writes to `/tmp/expected.txt` and `/tmp/received.txt`.

Note, that `${{ steps.step_one.outputs.json }}` is unaffected by the variable expansion prevention, as GitHub replaces values in the command before evaluating it.

Also, please note that the `heredoc` cannot be indented (such as within an `if-else` block).

Lastly, the `git diff` should display what is different between `/tmp/expected.txt` (defined by `step_two`), and `/tmp/received.txt` (saved in `step_two`, but defined by what we export from `step_one`). If nothing is different, then the `exit_code` will be `0`, and the step will pass. If something is different, then the `exit_code` will be `1`, and the step will error.


# Random Notes 

Ideally, I would be able to do this 

`uses: ${{ github.repository }}@${{ github.head_ref }}`

to check if the current `HEAD` functions correctly as a GitHub Action, but this syntax doesn't appear to be possible at the moment. 


```
  - name: Print Env Vars
        run: |
          (
          cat << EOF
          github.actor
          ${{ github.actor }}

          github.event
          ${{ github.event }}

          github.event_name
          ${{ github.event_name }}

          github.githubassets
          ${{ github.githubassets }}

          github.head_ref
          ${{ github.head_ref }}

          github.ref
          ${{ github.ref }}

          github.ref_name
          ${{ github.ref_name }}

          github.repository
          ${{ github.repository }}

          github.run_id
          ${{ github.run_id }}

          github.workflow
          ${{ github.workflow }}

          github.workspace
          ${{ github.workspace }}

          EOF
          );
```


```
github.actor
jadutter

github.event
Object

github.event_name
pull_request

github.githubassets


github.head_ref
hotfix/patch-action

github.ref
refs/pull/3/merge

github.ref_name
3/merge

github.repository
jadutter/jq-action

github.run_id
7303475767

github.workflow
GitHub-CI: valid image

github.workspace
/home/runner/work/jq-action/jq-action
```


Command to spin up a docker container in the terminal. 
```
docker run --rm  --name test-shells -it alpine
```
