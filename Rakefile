# frozen_string_literal: true

require "rake"

namespace :release do
  desc "Bump version, update CHANGELOG.md, and tag the release (local only)"
  task :create do
    app_version_file = ".app_version"

    # Ensure .app_version file exists
    unless File.exist?(app_version_file)
      puts "Error: #{app_version_file} file not found!"
      exit 1
    end

    # Read the version from the .app_version file
    version = File.read(app_version_file).strip

    # Validate the version format (e.g., v1.0.0)
    unless version.match?(/^v\d+\.\d+\.\d+$/)
      puts "Error: Invalid version format in #{app_version_file}. Expected format: v<major>.<minor>.<patch> (e.g., v1.0.0)"
      exit 1
    end

    # Update or create the CHANGELOG.md file
    changelog_path = File.join(Dir.pwd, "CHANGELOG.md")
    unless File.exist?(changelog_path)
      puts "CHANGELOG.md not found. Creating a new file..."
      File.open(changelog_path, "w") do |file|
        file.puts("# Changelog\n\n")
      end
    end

    # Find the previous tag
    previous_tag = `git describe --tags --abbrev=0`.strip
    unless $?.success?
      puts "Error: Unable to find the previous tag. Is this the first release?"
      exit 1
    end

    # Get commits between the last tag and the new tag
    commits = `git log #{previous_tag}..HEAD --pretty=format:"- %s (%an)"`.strip.split("\n")
    if commits.empty?
      puts "No new commits to include in the changelog since the previous tag #{previous_tag}."
      exit 1
    end

    # Prepare new changelog content
    new_changelog_content = []
    new_changelog_content << "## [#{version}] - #{Time.now.strftime('%Y-%m-%d')}"
    new_changelog_content.concat(commits)
    new_changelog_content << "\n"

    # Insert new content at the top of the changelog
    existing_changelog = File.read(changelog_path)
    File.open(changelog_path, "w") do |file|
      file.puts(new_changelog_content.join("\n"))
      file.puts(existing_changelog)
    end

    # Stage and commit the updated CHANGELOG.md
    sh "git add ."
    sh "git commit -m 'Bump application to #{version}'"

    # Create the Git tag
    sh "git tag -a #{version} -m 'Bump application to #{version}'"

    puts "Version bumped to #{version}, and the tag #{version} has been created locally."
  end
end
