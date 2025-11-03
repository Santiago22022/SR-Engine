package;

import Note;
import flixel.group.FlxTypedGroup;

class NotePool extends FlxTypedGroup<Note>
{
    public function new(maxSize:Int = 0)
    {
        super(maxSize);
    }

    public function get():Note
    {
        var note:Note = recycle();
        if (note == null)
        {
            note = new Note();
        }
        return note;
    }

    public function put(note:Note):Void
    {
        if (note != null)
        {
            note.kill();
            note.active = false;
            note.visible = false;
            this.remove(note, true);
            this.add(note);
        }
    }
}