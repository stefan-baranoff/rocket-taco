def parse argv

  types = {"-s" => 'string', "-p" => 'int', "-c" => 'string'}
  defaults = {'-s' => 'localhost', '-p' => 3000, '-c' => 'general'}

  help = "usage: rockettaco [args]\n\t-s [SERVER]\n\t-p [PORT]\n\t-c [CHANNEL]\n\t-h"

  args = defaults
  label = ''
  for arg in argv
    if arg[0] == '-'
      label = arg
      if !types.include? label
        puts help
        exit 1
      end
    else
      if label == ''
        puts help
        exit 1
      end
      if types[label] == 'int'
        arg = arg.to_i
      end
      args[label] = arg
    end
  end
  args
end

parse ARGV
