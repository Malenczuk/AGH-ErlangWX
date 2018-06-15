%%%-------------------------------------------------------------------
%%% @author mdronski
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Jun 2018 15:03
%%%-------------------------------------------------------------------
-module(gui).
-author("mdronski").
-include_lib("wx/include/wx.hrl").
-export([start/0]).


start() ->
  Server = wx:new(),
  State = make_window(Server),
  loop(State).


make_window(Server) ->
  Frame = wxFrame:new(Server, -1, "Text editor", [{size, {1100, 800}}]),
  Panel = wxScrolledWindow:new(Frame),
  wxScrolledWindow:enableScrolling(Panel, false, true),

%%  Initialise menu bar
  MenuBar = wxMenuBar:new(),
  wxFrame:setMenuBar (Frame, MenuBar),
  FileMn = wxMenu:new(),
  wxMenuBar:append (MenuBar, FileMn, "&File"),
  Quit = wxMenuItem:new ([{id,400},{text, "&Quit"}]),
  wxMenu:append (FileMn, Quit),
  OpenFile = wxMenuItem:new ([{id,401},{text, "&Open"}]),
  wxMenu:append (FileMn, OpenFile),
  SaveFile = wxMenuItem:new ([{id,402},{text, "&Save"}]),
  wxMenu:append (FileMn, SaveFile),
  SaveFileAs = wxMenuItem:new ([{id,403},{text, "&Save as"}]),
  wxMenu:append (FileMn, SaveFileAs),
  wxFrame:connect (Frame, command_menu_selected),


%%  Initialise notebook
  Notebook = wxNotebook:new(Panel, 999),
  Page0 = insertPage(Notebook, "untitled.txt", ""),

%%  Initialise file list
  ListSizer = wxFlexGridSizer:new(1, 1, 10, 10),
  CheckListBox = wxCheckListBox:new(Panel, 1234, [{size, {150, 100}}]),
  wxSizer:add(ListSizer, CheckListBox, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}, {border, 10}]),
  wxFlexGridSizer:addGrowableRow(ListSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(ListSizer, 0, [{proportion, 1}]),

  fillChecklist(CheckListBox),
  wxFrame:connect(Frame, command_listbox_doubleclicked),

%%  Initialise notebook sizer
  NotebookSizer = wxFlexGridSizer:new(1, 1, 10, 5),
  wxFlexGridSizer:addGrowableRow(NotebookSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(NotebookSizer, 0, [{proportion, 1}]),

%%  Initialise main sizer
  MainSizer = wxFlexGridSizer:new(1, 2, 10, 10),
  wxSizer:add(MainSizer, ListSizer, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}]),
  wxSizer:add(MainSizer, Notebook, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}]),
  wxFlexGridSizer:addGrowableRow(MainSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(MainSizer, 1, [{proportion, 1}]),
  wxPanel:setSizer(Panel, MainSizer, []),

%%  connect and show window
  wxFrame:show(Frame),
  wxFrame:connect(Frame, close_window),
  wxPanel:connect(Panel, command_button_clicked),

  {Frame, Notebook, CheckListBox, #{0 => Page0}}.

loop(State) ->
  {Frame, Notebook, CheckListBox, TextCtrlMap} = State,

  receive
%%    Closing window
    #wx{event = #wxClose{}} ->
      io:format("~p Closing window ~n", [self()]),
      wxWindow:destroy(Frame),
      ok;

%%    Menu close window
    #wx{id = 400, event = #wxCommand{type = command_menu_selected}} ->
      io:format("~p Closing window ~n", [self()]),
      wxWindow:destroy(Frame);

%%  Save file from menu
    #wx{id = 402, event = #wxCommand{type = command_menu_selected}} ->
      Text = getCurrentText(Notebook, TextCtrlMap),
      Path = getSelectedFileName(Notebook),
      file:write_file(Path, Text),
      NewCheckList = updateChecklist(CheckListBox, Path),
      loop({Frame, Notebook, NewCheckList, TextCtrlMap});

%%    Save as from menu
    #wx{id = 403, event = #wxCommand{type = command_menu_selected}} ->
      Text = getCurrentText(Notebook, TextCtrlMap),
      Path = getPathFromPicker(Frame, save),
      file:write_file(Path, Text),
      io:format("~p ~n", [Path]),
      NewCheckList = updateChecklist(CheckListBox, Path),

      loop({Frame, Notebook, NewCheckList, TextCtrlMap});

%%    Open file from menu
    #wx{id = 401, event = #wxCommand{type = command_menu_selected}} ->
      Path = getPathFromPicker(Frame, open),
      {ok, Data} = file:read_file(Path),
      TextCtrl = insertPage(Notebook, Path, Data),
      wxNotebook:changeSelection(Notebook, wxNotebook:getPageCount(Notebook)-1),
      NewMap = maps:put(wxNotebook:getSelection(Notebook), TextCtrl, TextCtrlMap),
      NewCheckList = updateChecklist(CheckListBox, Path),
      loop({Frame, Notebook, NewCheckList, NewMap});

%%    Open file from check list
    #wx{id = 1234, event = #wxCommand{type =  command_listbox_doubleclicked}} ->
      Path = wxListBox:getString(CheckListBox, wxListBox:getSelection(CheckListBox)),
      {ok, Data} = file:read_file(Path),
      TextCtrl = insertPage(Notebook, Path, Data),
      wxNotebook:changeSelection(Notebook, wxNotebook:getPageCount(Notebook)-1),
      NewMap = maps:put(wxNotebook:getSelection(Notebook), TextCtrl, TextCtrlMap),
      loop({Frame, Notebook, CheckListBox, NewMap});

%%    Default
      Msg ->
      io:format("loop default triggered: Got ~n ~p ~n", [Msg]),
      loop(State)

  end.


insertPage(Notebook, Title, Content) ->
  Page1 = wxScrolledWindow:new(Notebook),
  wxNotebook:addPage(Notebook, Page1, Title, []),
  PageSizer = wxFlexGridSizer:new(1, 1, 10, 5),
  Text = wxTextCtrl:new(Page1, 111, [{style, ?wxTE_MULTILINE}, {style, ?wxTE_NO_VSCROLL}]),
  wxSizer:add(PageSizer, Text, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}, {border, 10}]),
  wxSizer:fit(PageSizer, Text),
  wxFlexGridSizer:addGrowableCol(PageSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableRow(PageSizer, 0, [{proportion, 1}]),
  wxPanel:setSizer(Page1, PageSizer, []),
  wxTextCtrl:setValue(Text, Content),
  wxWindow:fit(Page1),
  Text.

fillChecklist(CheckList) ->
  {ok, Dir} = file:get_cwd(),
  {ok, FileNames} = file:list_dir(Dir),
  lists:foldl(fun(FileName, _) -> wxCheckListBox:append(CheckList, FileName), 0 end, 0, FileNames),
  ok.

getSelectedFileName(Notebook) ->
  wxNotebook:getPageText(Notebook, wxNotebook:getSelection(Notebook)).

getCurrentText(Notebook, TextCtrlMap) ->
  wxTextCtrl:getValue(maps:get(wxNotebook:getSelection(Notebook), TextCtrlMap)).

updateChecklist(CheckList, FileName) ->
  case wxCheckListBox:findString(CheckList, FileName) of
    ?wxNOT_FOUND -> wxCheckListBox:append(CheckList, FileName),
      CheckList;
    _ -> CheckList
  end.

getPathFromPicker(Frame, Type) ->
  FilePicker = case Type of
                 open -> wxFileDialog:new(Frame);
                 save -> wxFileDialog:new(Frame, [{style, ?wxFD_SAVE}])
               end,
  wxFileDialog:showModal(FilePicker),
  Path = wxFileDialog:getPath(FilePicker),
  [FileName | _] = string:split(string:reverse(Path), "/"),
  string:reverse(FileName).
