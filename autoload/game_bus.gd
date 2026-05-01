extends Node

@warning_ignore("unused_signal")
signal screen_state_changed(state: int)
@warning_ignore("unused_signal")
signal interaction_focus_changed(object_id: String)
@warning_ignore("unused_signal")
signal prompt_notice_requested(text: String)

@warning_ignore("unused_signal")
signal dialogue_started(lines: Array)
@warning_ignore("unused_signal")
signal dialogue_finished
@warning_ignore("unused_signal")
signal choice_started(object_id: String, options: Array)
@warning_ignore("unused_signal")
signal choice_selected(object_id: String, key: String)

@warning_ignore("unused_signal")
signal verdict_requested
@warning_ignore("unused_signal")
signal verdict_submitted(key: String)
@warning_ignore("unused_signal")
signal ending_requested(ending_id: String)

@warning_ignore("unused_signal")
signal death_started(reason: String)
@warning_ignore("unused_signal")
signal loop_restarted(loop_count: int)
