SK's Scale
Copyright (c) 2009 sk89q <http://sk89q.therisenrealm.com>
Licensed under the GNU Lesser General Public License v3

Introduction
------------

This is a scale that uses only applyForce to measure mass. Constraints
and masses are _not_ looked up. The scale also supports a tare function.

Usage
-----

Hook up an entity to the E2 chip's E input. Wire the other inputs and
outputs respectively.

Note that a lower precision will prevent the scale surface from
drooping with greater weights, but precision will be lost.