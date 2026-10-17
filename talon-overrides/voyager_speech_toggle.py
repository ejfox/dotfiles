from talon import Module, actions

mod = Module()


@mod.action_class
class Actions:
    def voyager_speech_toggle():
        """Toggle Talon speech on/off. Bound to F19, sent by the Voyager's layer-2 right-hand "0" key."""
        if actions.speech.enabled():
            actions.speech.disable()
        else:
            actions.speech.enable()
