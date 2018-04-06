# {
#   resource_state: 2,
#   athlete: {
#     id: 26462176,
#     resource_state: 1
#   },
#   name: "First Time Breaking 14",
#   distance: 22539.6,
#   moving_time: 7586,
#   elapsed_time: 7686,
#   total_elevation_gain: 144.9,
#   type: Run,
#   workout_type: 0,
#   id: 1477353766,
#   external_id: A0254694-2A56-49FE-BACE-97CE937D748D,
#   upload_id: 1591925390,
#   start_date: 2018-03-28T23:51:34Z,
#   start_date_local: 2018-03-28T19:51:34Z,
#   timezone: (GMT-05:00) America/New_York,
#   utc_offset: -14400.0,
#   start_latlng: [40.682943, -73.914698],
#   end_latlng: [40.734301, -73.984049],
#   location_city: nil,
#   location_state: nil,
#   location_country: ,
#   start_latitude: 40.682943,
#   start_longitude: -73.914698,
#   achievement_count: 0,
#   kudos_count: 5,
#   comment_count: 0,
#   athlete_count: 1,
#   photo_count: 0,
#   map: {
#     id: a1477353766,
#     summary_polyline: "k{hwFzmcbMb[cGfg@pCbUrt@wIhkEsPzjA^tU_FnAiFsAccAxo@{F|GoZxKiNrIoFUsAdDcNpEtAr@[kEqAlA_@yAyAjCzAwDJiJoNZiAyJxAkD~LL|@yAvBs{AyJmhAwn@hq@uAdFkM_AiA~HiCv@{h@zgC~Rov@\\kCmBmAFkEe_@gKgv@mIwFtBaGrHDtBgFp@wDrIeHzVbPfL}EnOyEmClEfDOgBuDcA`C`DdAEQqAyDkA",
#     resource_state: 2
#   },
#   trainer: false,
#   commute: false,
#   manual: false,
#   private: false,
#   flagged: false,
#   gear_id: nil,
#   from_accepted_tag: false,
#   average_speed: 2.971,
#   max_speed: 9.3,
#   has_heartrate: false,
#   elev_high: 50.8,
#   elev_low: -0.8,
#   pr_count: 0,
#   total_photo_count: 1,
#   has_kudoed: false
# }

Fabricator(:activity) do
  strava_id { Fabricate.sequence(:user_id) { |i| "12345677892806#{i}" } }
  type 'Run'
  name { Faker::Internet.user_name }
  start_date { DateTime.parse('2018-02-20T18:02:13Z') }
  start_date_local { DateTime.parse('2018-02-20T10:02:13Z') }
  distance 22_539.6
  moving_time 7586
  elapsed_time 7686
  average_speed 2.971
  total_elevation_gain 144.9
  map { |activity| Fabricate.build(:map, activity: activity) }
  after_create do
    map.save!
  end
end
