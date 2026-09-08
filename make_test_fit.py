#!/usr/bin/env python3
"""生成测试 FIT：7 个速度区间各 10 秒递增（5/15/25/35/45/55/65 km/h），用于模拟器回放测分区变色"""
import time
from fit_tool.fit_file_builder import FitFileBuilder
from fit_tool.profile.messages.file_id_message import FileIdMessage
from fit_tool.profile.messages.record_message import RecordMessage
from fit_tool.profile.messages.session_message import SessionMessage
from fit_tool.profile.profile_type import FileType, Manufacturer, Sport

OUT = '/Users/galaxyxin/GarminProjects/ColorfulSpeedZones/test_zones.fit'

# fit-tool 时间戳单位是 ms（Unix 毫秒）
now_ms = int(time.time() * 1000)
start_ms = now_ms - 70 * 1000  # 70 秒前开始

builder = FitFileBuilder()

file_id = FileIdMessage()
file_id.type = FileType.ACTIVITY
file_id.manufacturer = Manufacturer.DEVELOPMENT
file_id.product = 0
file_id.time_created = start_ms
builder.add(file_id)

zones_kmh = [5, 15, 25, 35, 45, 55, 65]  # 每档中间值
total_dist_m = 0.0
for zi, kmh in enumerate(zones_kmh):
    mps = kmh / 3.6
    for sec in range(10):
        rec = RecordMessage()
        rec.timestamp = start_ms + (zi * 10 + sec) * 1000
        rec.speed = mps
        rec.enhanced_speed = mps
        total_dist_m += mps
        rec.distance = total_dist_m
        builder.add(rec)

session = SessionMessage()
session.start_time = start_ms
session.total_elapsed_time = 70.0
session.total_timer_time = 70.0
session.total_distance = total_dist_m
session.sport = Sport.CYCLING
builder.add(session)

fit = builder.build()
data = fit.to_bytes()
with open(OUT, 'wb') as f:
    f.write(data)
print(f'生成完成: {OUT} ({len(data)} bytes)')
