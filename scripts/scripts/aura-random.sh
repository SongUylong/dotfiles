#!/usr/bin/env bash
# Cycles through a random static color on each press

random_color() {
	printf '%02x%02x%02x' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256))
}

asusctl aura effect static -c "$(random_color)"
