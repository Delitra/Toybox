SK's Paint
Copyright (c) 2009 sk89q <http://sk89q.therisenrealm.com>
Licensed under the GNU Lesser General Public License v3

Introduction
------------

This is a set of an E2 script to do the painting, a zASM (zC) program
to draw a color selector display, and another E2 script to handle
color selection.

- When the cursor on a digital screen is moved too quickly, the E2
  script will not detect the intermediate points that the cursor
  passed over, meaning that pixels will have to be drawn manually
  pixel by pixel. To solve this, a line drawing algorithm is
  implemented to interpolate points between the start and end points.
- A full color selector is implemented that allows users to select a
  wide range of colors from a full range of hue and a full range of
  saturation. The value (in HSV) is fixed, however.
- Large brush drawing mode.
- Quick erase mode (can be wired to right click).
- Color picker.

Usage
-----

Create two digital screens, one having the resolution of 40x40 (for
the painting) and another that is 12x12 (for the color selection). Place
two graphics tablets over each digital screen. Wire the components as
necessary.

Known Issues
------------

- The color selector image takes quite an amount of time to draw.