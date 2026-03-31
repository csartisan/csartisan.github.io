#!/usr/bin/env ruby
# migrate_tags.rb
#
# One-time migration: converts legacy tag-based flags to explicit front matter booleans.
#   tags: [sticky]   →  jumbotron: true  (tag removed from array)
#   tags: [featured] →  featured: true   (tag removed from array)
#
# Works via regex on raw front matter to avoid Ruby 3.1+ YAML class-loading restrictions.
#
# Usage:
#   ruby migrate_tags.rb          # dry run (shows what would change)
#   ruby migrate_tags.rb --apply  # write changes to disk

DRY_RUN = !ARGV.include?("--apply")
POSTS_DIR = File.join(__dir__, "_posts")

puts DRY_RUN ? "DRY RUN — no files will be written. Pass --apply to save changes.\n\n" \
              : "Applying changes...\n\n"

changed = 0

Dir.glob(File.join(POSTS_DIR, "*.md")).sort.each do |path|
  content = File.read(path, encoding: "utf-8")

  unless content =~ /\A(---\s*\n)(.*?\n)(---\s*\n)(.*)\z/m
    puts "SKIP (no front matter): #{File.basename(path)}"
    next
  end

  open_fence = $1
  fm          = $2
  close_fence = $3
  body        = $4

  # Check for the tags we care about
  next unless fm =~ /\btags\s*:/

  # Extract the raw tags value (handles both inline [ ] and block list styles)
  tags_line = fm[/^tags\s*:.*/]
  next unless tags_line

  needs_jumbotron = tags_line.include?("sticky")
  needs_featured  = tags_line.include?("featured")
  next unless needs_jumbotron || needs_featured

  puts "#{File.basename(path)}:"
  puts "  tags line before: #{tags_line.strip}"

  new_fm = fm.dup

  # Remove 'sticky' from the inline array, e.g. [ sticky, other ] → [ other ]
  if needs_jumbotron
    new_fm.gsub!(/(\btags\s*:\s*\[)[^\]]*\]/) do |m|
      items = m.sub(/\btags\s*:\s*\[/, "").sub(/\]$/, "")
                .split(",").map(&:strip)
                .reject { |t| t == "sticky" }
      "tags: [ #{items.join(", ")} ]"
    end
    # Add jumbotron: true before the tags line (if not already present)
    unless new_fm =~ /^jumbotron\s*:/
      new_fm.sub!(/^(tags\s*:.*)/, "jumbotron: true\n\\1")
    end
  end

  if needs_featured
    new_fm.gsub!(/(\btags\s*:\s*\[)[^\]]*\]/) do |m|
      items = m.sub(/\btags\s*:\s*\[/, "").sub(/\]$/, "")
                .split(",").map(&:strip)
                .reject { |t| t == "featured" }
      "tags: [ #{items.join(", ")} ]"
    end
    unless new_fm =~ /^featured\s*:/
      new_fm.sub!(/^(tags\s*:.*)/, "featured: true\n\\1")
    end
  end

  puts "  tags line after:  #{new_fm[/^tags\s*:.*/].strip}"
  puts "  + jumbotron: true" if needs_jumbotron
  puts "  + featured: true"  if needs_featured
  puts

  unless DRY_RUN
    File.write(path, "#{open_fence}#{new_fm}#{close_fence}#{body}", encoding: "utf-8")
  end

  changed += 1
end

puts "#{changed} file(s) #{DRY_RUN ? "would be" : "were"} updated."
