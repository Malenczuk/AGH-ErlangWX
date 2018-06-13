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
-include("messenger.hrl").
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

  MainSizer = wxFlexGridSizer:new(1, 2, 10, 10),
  ListSizer = wxFlexGridSizer:new(1, 1, 10, 10),
  TextSizer = wxFlexGridSizer:new(1, 1, 10, 5),

  Notebook = wxNotebook:new(Panel, 999),
  insertPage(Notebook, "untitled.txt", ""),

%%  Text1 = wxTextCtrl:new(Panel, 1001, [{style, ?wxTE_MULTILINE}, {style, ?wxTE_NO_VSCROLL}]),

  CheckListBox = wxCheckListBox:new(Panel, 1234, [{size, {150, 100}}]),
  wxSizer:add(ListSizer, CheckListBox, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}, {border, 10}]),
  wxFlexGridSizer:addGrowableRow(ListSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(ListSizer, 0, [{proportion, 1}]),

  fillChecklist(CheckListBox),
  wxFrame:connect (Frame, command_listbox_doubleclicked),


%%  wxSizer:add(TextSizer, Text1, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}, {border, 10}]),

  wxFlexGridSizer:addGrowableRow(TextSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(TextSizer, 0, [{proportion, 1}]),

  wxSizer:add(MainSizer, ListSizer, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}]),
  wxSizer:add(MainSizer, Notebook, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}]),
  wxFlexGridSizer:addGrowableRow(MainSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(MainSizer, 1, [{proportion, 1}]),


  wxPanel:setSizer(Panel, MainSizer, []),
  wxFrame:show(Frame),

  wxFrame:connect(Frame, close_window),
  wxPanel:connect(Panel, command_button_clicked),

  {Frame, Notebook, "untitled.txt", #{}}.

loop(State) ->
  {Frame, Notebook, SelectedPath, Contents} = State,
  receive
    #wx{event = #wxClose{}} ->
      io:format("~p Closing window ~n", [self()]),
      wxWindow:destroy(Frame),
      ok;

    #wx{id = 400, event = #wxCommand{type = command_menu_selected}} ->
      io:format("~p Closing window ~n", [self()]),
      wxWindow:destroy(Frame);

    #wx{id = 401, event = #wxCommand{type = command_menu_selected}} ->
      FilePicker = wxFileDialog:new(Frame),
      wxFileDialog:showModal(FilePicker),
      Path = wxFileDialog:getPath(FilePicker),
      {ok, Data} = file:read_file(Path),
      [FileName | _] = string:split(string:reverse(Path), "/"),
      TextCtrl = insertPage(Notebook, string:reverse(FileName), Data),
      wxNotebook:changeSelection(Notebook, wxNotebook:getPageCount(Notebook)-1),
      NewMap = maps:put(wxNotebook:getSelection(Notebook), TextCtrl, Contents),
      loop({Frame, Notebook, Path, NewMap});


    #wx{id = 402, event = #wxCommand{type = command_menu_selected}} ->
      EditedText = maps:get(wxNotebook:getSelection(Notebook), Contents),
      file:write_file(SelectedPath, EditedText),
      loop(State);

    #wx{id = 403, event = #wxCommand{type = command_menu_selected}} ->
      EditedText = wxTextCtrl:getValue(maps:get(wxNotebook:getSelection(Notebook), Contents)),

      FilePicker = wxFileDialog:new(Frame, [{style, ?wxFD_SAVE}]),
      wxFileDialog:setMessage(FilePicker, "Save"),
      wxFileDialog:showModal(FilePicker),
      Path = wxFileDialog:getPath(FilePicker),

      file:write_file(Path, EditedText),
      loop(State);

    #wx{id = 1234, event = #wxCommand{type =  command_listbox_doubleclicked}} ->
      io:format("xdxdxdx ~n", []),

      loop(State);

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
  lists:foldl(fun(FileName, Acc) -> wxCheckListBox:append(CheckList, FileName), 0 end, 0, FileNames),
  ok.