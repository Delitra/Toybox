import wx

class MIDI2E2App(wx.App):
    def OnInit(self):
        frame = MainFrame(None, wx.ID_ANY, "midi2e2 GUI")
        frame.Show(True)
        self.SetTopWindow(frame)
        return True

class MainFrame(wx.Frame):
    def __init__(self, parent, ID, title):
        wx.Frame.__init__(self, parent, ID, title,
                          wx.DefaultPosition, wx.Size(400, 400),
                          wx.MINIMIZE_BOX | wx.SYSTEM_MENU | wx.CAPTION | wx.CLOSE_BOX | wx.CLIP_CHILDREN)
        
        self.make_menu()        
        self.panel = MainPanel(self, wx.ID_ANY)
    
    def make_menu(self):
        file_menu = wx.Menu()
        quit_item = file_menu.Append(wx.ID_EXIT, "&Quit", "Quit the program")
        wx.EVT_MENU(self, wx.ID_EXIT, self.evt_close)
        self.menubar = wx.MenuBar()
        self.menubar.Append(file_menu, "&File")
        self.SetMenuBar(self.menubar)
    
    def evt_close(self, evt):
        self.Close(True)

class MainPanel(wx.Panel):
    def __init__(self, parent, id):
        wx.Panel.__init__(self, parent, id)
        
        self.midi_input = FileInputPanel(self, wx.ID_ANY,
                                        title="Browse for MIDI file...",
                                        wildcard="MIDI files (*.mid;*.mid)|*.mid;*.midi|All files (*.*)|*.*")
        self.output_input = FileInputPanel(self, wx.ID_ANY,
                                        title="Save output file...",
                                        wildcard="Text file (*.txt)|*.txt|Data file (*.dat)|*.dat|Binary file (*.bin)|*.bin",
                                        open=False)
        self.tempo = wx.TextCtrl(self, wx.ID_ANY)
        
        formats = (
            "Expression 2",
            "LFMIDI",
        )
        self.format = wx.ComboBox(self, wx.ID_ANY, style=wx.CB_DROPDOWN | wx.CB_READONLY, choices=formats)
        
        self.psizer = wx.BoxSizer()
        self.sizer = wx.FlexGridSizer(2, 2, 5, 5)
        self.sizer.AddGrowableCol(1, 1)
        self.sizer.AddMany((
            (wx.StaticText(self, wx.ID_ANY, "MIDI file: "), 1, wx.ALIGN_CENTER_VERTICAL),
            (self.midi_input, 1, wx.EXPAND),
            (wx.StaticText(self, wx.ID_ANY, "Output file: "), 1, wx.ALIGN_CENTER_VERTICAL),
            (self.output_input, 1, wx.EXPAND),
            (wx.StaticText(self, wx.ID_ANY, "Format: "), 1, wx.ALIGN_CENTER_VERTICAL),
            (self.format, 1),
            (wx.StaticText(self, wx.ID_ANY, "Tempo: "), 1, wx.ALIGN_CENTER_VERTICAL),
            (self.tempo, 1)
        ))
        self.psizer.Add(self.sizer, 1, wx.EXPAND | wx.ALL, 7)
        self.SetSizer(self.psizer)
        self.psizer.Fit(self)

class FileInputPanel(wx.Panel):
    def __init__(self, parent, id, open=True, title="Browse...", wildcard="*.*"):
        wx.Panel.__init__(self, parent, id)
        
        self.open = open
        self.dir = ""
        self.title = title
        self.wildcard = wildcard
        
        self.sizer = wx.FlexGridSizer(1, 2, 0, 5)
        self.sizer.AddGrowableCol(0, 1)
        
        self.button = wx.Button(self, wx.ID_ANY, "Browse...")
        self.button.Bind(wx.EVT_BUTTON, self.evt_browse)
        self.text = wx.TextCtrl(self, wx.ID_ANY)
        
        self.sizer.AddMany((
            (self.text, 1, wx.EXPAND),
            (self.button, 1),
        ))
        
        self.SetSizer(self.sizer)
        self.SetAutoLayout(1)
        self.sizer.Fit(self)
    
    def evt_browse(self, evt):
        if self.open:
            dlg = wx.FileDialog(self, self.title, self.dir, "",
                                self.wildcard, wx.FD_OPEN | wx.FD_FILE_MUST_EXIST)
        else:
            dlg = wx.FileDialog(self, self.title, self.dir, "",
                                self.wildcard, wx.FD_SAVE | wx.FD_OVERWRITE_PROMPT)
        if dlg.ShowModal() == wx.ID_OK:
            self.dir = dlg.GetDirectory()
            self.text.SetValue(dlg.GetPath())
        dlg.Destroy()
    
    def value(self):
        return self.text.GetValue()

app = MIDI2E2App(0)
app.MainLoop()
