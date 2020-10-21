obs = obslua

source1_name = ""
source2_name = ""
scene1_name = ""
scene2_name = ""
hotkey_id = obs.OBS_INVALID_HOTKEY_ID

initial_position = 800
scene_item = nil
source_name = nil
scene_name = nil
duration_ms = 500
target_width = 1920
target_height = 1080
fps = 60

-- Computed
total_frames = fps * (duration_ms / 1000)
change_per_frame = initial_position / total_frames

-- Internal state
playing = false
position = initial_position

-- Called to get a description
function script_description()
	return "RCVolus: Fades a certain scene to full.\n\nMade by Larce"
end

-- Called when the hotkeys are pressed
function fly_full_pressed(pushed)
  fly_full(pushed)
  return false
end
function fly_full(pushed)
  if not pushed then return end
  if playing then return end

  playing = true
  position = initial_position
  obs.timer_add(timer_callback, duration_ms)

  local scene_source = obs.obs_frontend_get_current_scene()
  local scene = obs.obs_scene_from_source(scene_source)
  
  scene_item = obs.obs_scene_find_source(scene, source1_name)
  source_name = source1_name
  scene_name = scene1_name
  if scene_item == nil then
    scene_item = obs.obs_scene_find_source(scene, source2_name)
    source_name = source2_name
    scene_name = scene2_name
  end
  if scene_item == nil then
    print("ERROR: no scene item found.")
    source_name = nil
    scene_name = nil
    playing = false
    return
  end

  print("Flying full: " .. source_name)
  obs.obs_source_release(scene_source)
end

-- Render tick
function render_call(seconds)
	if not playing then
		return
  end
  
  position = position - change_per_frame
  local size_y = 1080 - position
  local size_x = math.ceil((size_y / 9) * 16)

  local scale_x = 1/target_width*size_x
  local scale_y = 1/target_height*size_y

	obs.obs_enter_graphics();
  -- Calculate new positions
  local pos = obs.vec2()
  pos.x = 0
  pos.y = position
  obs.obs_sceneitem_set_pos(scene_item, pos)

  local scale = obs.vec2()
  scale.x = scale_x
  scale.y = scale_y
  obs.obs_sceneitem_set_scale(scene_item, scale)
  obs.obs_leave_graphics();
end

-- Clean everything up after transition is finished
function timer_callback()
  if not playing then return end

  -- transition to new scene
  scene = obs.obs_get_source_by_name(scene_name)
  -- obs.obs_frontend_set_current_transition(obs.obs_get_source_by_name("Cut"))
  print(type(obs.obs_get_source_by_name("cut")))
  obs.obs_frontend_set_current_scene(scene)

  position = initial_position
  local size_y = 1080 - position
  local size_x = math.ceil((size_y / 9) * 16)

  local scale_x = 1/target_width*size_x
  local scale_y = 1/target_height*size_y

	-- obs.obs_enter_graphics();
  -- Calculate new positions
  local pos = obs.vec2()
  pos.x = 0
  pos.y = position
  obs.obs_sceneitem_set_pos(scene_item, pos)

  local scale = obs.vec2()
  scale.x = scale_x
  scale.y = scale_y
  obs.obs_sceneitem_set_scale(scene_item, scale)
  -- obs.obs_leave_graphics();

	playing = false
	obs.remove_current_callback()
end

-- Called when the user changes settings
function script_update(settings)
  source1_name = obs.obs_data_get_string(settings, "source1")
  source2_name = obs.obs_data_get_string(settings, "source2")
  scene1_name = obs.obs_data_get_string(settings, "scene1")
  scene2_name = obs.obs_data_get_string(settings, "scene2")
end

-- Define settings for the script
function script_properties()
	local props = obs.obs_properties_create()

  local properties_source1 = obs.obs_properties_add_list(props, "source1", "PiP Source 1", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
  local properties_scene1 = obs.obs_properties_add_list(props, "scene1", "PiP Scene 1", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
  local properties_source2 = obs.obs_properties_add_list(props, "source2", "PiP Source 2", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
  local properties_scene2 = obs.obs_properties_add_list(props, "scene2", "PiP Scene 2", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)

	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			local name = obs.obs_source_get_name(source)
      obs.obs_property_list_add_string(properties_source1, name, name)
      obs.obs_property_list_add_string(properties_source2, name, name)
		end
	end
  obs.source_list_release(sources)
  
  local scene_names = obs.obs_frontend_get_scene_names()
  if scene_names ~= nil then
    for _, name in ipairs(scene_names) do
      obs.obs_property_list_add_string(properties_scene1, name, name)
      obs.obs_property_list_add_string(properties_scene2, name, name)
    end
  end

	-- obs.obs_properties_add_button(props, "fly_full_hotkey", "RCVolus: Fly full", fly_full_button_clicked)

	return props
end

function save_hotkey(settings, hotkey_id, name)
  local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, name, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end
function load_hotkey(settings, hotkey_id, name)
  local hotkey_save_array = obs.obs_data_get_array(settings, name)
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

-- We need to manually save the hotkey
-- Called whenever the script data is saved
function script_save(settings)
  save_hotkey(settings, hotkey_id, "fly_full_hotkey")
end

-- Called on script load / startup
function script_load(settings)
  local sh = obs.obs_get_signal_handler()
  
  hotkey_id = obs.obs_hotkey_register_frontend("fly_full_hotkey", "RCVolus: Fly full", fly_full_pressed)
  
  load_hotkey(settings, hotkey_id, "fly_full_hotkey")

  obs.obs_add_tick_callback(render_call)
end