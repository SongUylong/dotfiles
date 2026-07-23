import datetime
import os
from kitty.fast_data_types import Screen
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_tab_with_powerline,
)
from kitty.utils import color_as_int

def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    end = draw_tab_with_powerline(
        draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )

    if is_last:
        now = datetime.datetime.now().strftime("%I:%M")
        right_status = f" {now} 🠸 🕒 "
        right_len = len(right_status)

        if screen.columns > end + right_len:
            screen.cursor.x = screen.columns - right_len
            fg = color_as_int(as_rgb(draw_data.inactive_tab_fg))
            bg = color_as_int(as_rgb(draw_data.tab_bar_bg))
            screen.cursor.fg = fg
            screen.cursor.bg = bg
            screen.draw(right_status)

    return end
