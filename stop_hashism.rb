#!/usr/bin/env ruby

# Ruby implementation of vogs https://github.com/vog/beautify_git_hash to
# improve your commits hashes.

# Call with wished starting chunk of hash (e.g. cafe, bad) as argument.

# Refer to the
# https://github.com/vog/beautify_git_hash/blob/master/beautify_git_hash.py
# original for great explanation.
# Digest git commit hashes here: https://gist.github.com/masak/2415865

# Released under the AGPLv3+
# Copyright 2022 Felix Wolfsteller

require 'digest'

MAX_MINUTES = 10

class GitCommitData
  TIMESTAMP_REGEX = /[0-9]+/ # We assume timezone of caller and data are same

  attr_accessor :original
  attr_accessor :template
  attr_accessor :author_timestamp
  attr_accessor :committer_timestamp

  def initialize data
    @original = data
    @template = create_template
    @author_timestamp, @committer_timestamp = original_timestamps
  end

  # returns original author, commiter timestamp in an array
  # not robust, will fail e.g. on name with digits
  def original_timestamps
    lines = @original.split("\n")

    author_timestamp    = lines.grep(/author/).first[TIMESTAMP_REGEX].to_i
    committer_timestamp    = lines.grep(/committer/).first[TIMESTAMP_REGEX].to_i

    return [author_timestamp, committer_timestamp]
  end

  def to_commit_hash(data=to_s)
    phrase = "commit %i\x00%s" % [data.length, data]
    Digest::SHA1.hexdigest phrase
  end

  def to_s
    @template % {
      author_timestamp: @author_timestamp,
      committer_timestamp: @committer_timestamp
    }
  end

  private

  # not robust, will fail e.g. on name with digits
  def create_template
    author_found, committer_found = false, false

    # replace timestamp with interpolation args
    lines = @original.split("\n").map do |line|
      if !author_found && line.start_with?('author')
        line.sub(TIMESTAMP_REGEX, '%{author_timestamp}')
      elsif !committer_found && line.start_with?('committer')
        line.sub(TIMESTAMP_REGEX, '%{committer_timestamp}')
      else
        line
      end
    end

    return lines.join("\n")+"\n"
  end
end

def main
  if ARGV.length == 0
    STDERR.puts "Call with argument(s)! '#{$PROGRAM_NAME} wished-hash1 wished-hash2 ...'"
    exit 1
  end

  data = GitCommitData.new(`git cat-file commit HEAD`)
  # starts with any of the given arguments
  wish = Regexp.new ARGV.map{|a| "^(%s)" % a}.join("|") 
  
  puts data.template
  
  (1..(MAX_MINUTES*60+1)).each do |a_offset|
    (a_offset..(MAX_MINUTES*60+1)).each do |c_offset|
      data.author_timestamp = data.author_timestamp + a_offset
      data.committer_timestamp = data.committer_timestamp + c_offset
      if data.to_commit_hash =~ wish
        puts "Found"
        puts data
        puts data.to_commit_hash
        puts [data.committer_timestamp, data.author_timestamp]
        puts
        puts "use:"
        puts "GIT_COMMITTER_DATE='%s' git commit --amend -C HEAD --date='%s'" % [data.committer_timestamp, data.author_timestamp]
        exit 0
      end
    end
  end
  
  STDERR.puts "Not found"
  exit 2
end

# Is this file being executed (otherwise e.g. in test)
if $0 == __FILE__
  main
end
