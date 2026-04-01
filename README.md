## Tools to build shiny apps with Claude & golem

For now, this is a work in progress.

## Examples

The examples in the `/examples` folder has been generated using the following prompts:

### GPS compare

Prompt:

```
Using the good practices defined in the current directory with `claude.md`, create the following golem application:

- One module that will read two GPX files that can either be uploaded, or (by default) use two GPX that are almost the same.
- One module that will display a graph of the GPX files on a leaflet map, allowing the user to compare the GPX. The leaflet should have no licence error when displaying the tiles.
- The user can select a color for each GPX
- The user can reverse the GPX
- One module will give a percentage of closeness between the two GPX

The design should be a bslib dashboard. Keep the colors simple and readable.

Create this app in a folder called generated/comparegpx
```

### Video organizer

Prompt:

```
Using the good practices defined in the current directory with `claude.md`, create the following golem application:

The application should be used to tag video inside a given folder, and then find back the video later on.

When the user connecct, they can either open a folder on their computer, or select one that they have previously worked in.

When the folder is selected, the user now has the following tabs:

- One to search for videos using a given tag or series of tags
  - The user can search using a textbox with free text
  - The user can select one or more tags to filter the video
  - The user can preview the video
  - The user can order the videos by date, size or name, something that looks like a mac / windows finder
  - The user can show the video in the enclosing folder, i.e. it open the folder on their laptop at the specified location
- One to tag videos from the folder
  - The user can manually add a new tag using free text, where the tags are separated by a comma
  - The user can add an existing tag
  - The user can remove an existing tag from a video
- One tab to export or import the sqlite db file.

The application should have a memory. Use an sqlite db to keep the information from one session to the other.

Use bslib, and make the application modern and user friendly.

Create this app in a folder called generated/videotager
```
