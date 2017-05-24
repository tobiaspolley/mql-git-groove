# Future feature ideas

- mql5 compatibility

- update property copyright in all src/ files w/o sub/

- `update_property_links="[true|false]"`:
  Updates \#property link in all project files in scr/ from project.info
  (sub/ is excluded)

- README.md:
  - link trading.tobiaspolley.com


- rethink binaries

# New features

+ Introducing release notes

+ Better README file (as markdown) pointing to resources:

  - wiki
  - latest release
  - release notes
  - install
  - lincense


+ Function GenerateReleaseFiles() is split up into two independent functions:

  + GenerateChangelog()
  + GenerateReadme()


- _projects.info_ gives control over three previously existing features:

  + `generate_chagelog="[true|false]"`:
    Creates CHANGELOG from 'git log' [true|false].
    Using GitHub makes CHANGELOG somewhat redundant, so it must be explicitly enabled.

  + `generate_readme="[true|false]"`:
    Creates a README file with project information and a table of content with checksums.
    Using GitHub asks for a better README, so it must be explicitly enabled.
    Enable when not using GitHub.

  + `generate_archive="[true|false]"`:
    Create a tarball of the project [true|false].
    Feature is redundant to GitHub functionality, so it can be disabled.
    Enable when not using GitHub.

+ Drop submodule _'doc'_. Assuming the best place to look for information is always the current wiki. This is linked to in the README.


# Fixed bugs

# Known bugs
