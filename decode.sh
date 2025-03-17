sed -E '
    :nextLine;
    # if not the end of the file
    $!{
      # add the next line to the pattern space
      N;
      # grab another line
      b nextLine;
    }



    # escape dollar sign
    s/\\$/\$/g;

    # escape double quotes
    s/\\\"/\"/g;

    # esape newline characters
    s/%0A/\n/g;
    s/%0D/\r/g;

    # escape percentage sign
    s/%25/%/g;

    # escape backslash characters
    s/\\\\/\\/g;

'