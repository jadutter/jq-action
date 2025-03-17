sed -E '
    :nextLine;
    # if not the end of the file
    $!{
      # add the next line to the pattern space
      N;
      # grab another line
      b nextLine;
    }
    # escape backslash characters
    s/\\/\\\\/g;

    # escape percentage sign
    s/%/%25/g;

    # esape newline characters
    s/\n/%0A/g;
    s/\r/%0D/g;

    # escape double quotes
    s/\"/\\\"/g;

    # escape dollar sign
    s/\$/\\$/g;
'