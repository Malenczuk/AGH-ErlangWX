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
  State = make_window(),
  loop(State).

make_window() ->
  Server = wx:new(),
  Frame = wxFrame:new(Server, -1, "Messenger", [{size, {600, 700}}]),
  Panel = wxScrolledWindow:new(Frame),
  wxScrolledWindow:enableScrolling(Panel, false, true),

  MainSizer = wxFlexGridSizer:new(1, 2, 10, 10),
  ListSizer = wxFlexGridSizer:new(1, 1, 10, 10),
  TextSizer = wxFlexGridSizer:new(2, 1, 10, 5),
  MsgSizer = wxFlexGridSizer:new(1, 2, 10, 10),

  Text1 = wxTextCtrl:new(Panel, 1001, [{style, ?wxTE_MULTILINE}, {style, ?wxTE_NO_VSCROLL}]),
  Text2 = wxTextCtrl:new(Panel, 2001, [{style, ?wxTE_MULTILINE}, {style, ?wxTE_NO_VSCROLL}, {size, {100, 125}}]),
  wxTextCtrl:setEditable(Text1, false),

  CheckListBox = wxCheckListBox:new(Panel, 1234, [{size, {150, 100}}]),
  wxSizer:add(ListSizer, CheckListBox, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}, {border, 5}]),
  wxFlexGridSizer:addGrowableRow(ListSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(ListSizer, 0, [{proportion, 1}]),

  SendButton = wxButton:new(Panel, 101, [{label, "&Send"}]),
  wxSizer:add(MsgSizer, Text2, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}, {border, 5}]),
  wxSizer:add(MsgSizer, SendButton, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}, {border, 5}]),
%%  wxFlexGridSizer:addGrowableRow(MsgSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(MsgSizer, 0, [{proportion, 1}]),

  wxSizer:add(TextSizer, Text1, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}, {border, 5}]),
  wxSizer:add(TextSizer, MsgSizer, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}]),

  wxFlexGridSizer:addGrowableRow(TextSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(TextSizer, 0, [{proportion, 1}]),

  wxSizer:add(MainSizer, ListSizer, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}]),
  wxSizer:add(MainSizer, TextSizer, [{proportion, 1}, {flag, ?wxALL bor ?wxEXPAND}]),
  wxFlexGridSizer:addGrowableRow(MainSizer, 0, [{proportion, 1}]),
  wxFlexGridSizer:addGrowableCol(MainSizer, 1, [{proportion, 1}]),


  wxPanel:setSizer(Panel, MainSizer, []),
  wxFrame:show(Frame),

  wxFrame:connect(Frame, close_window),
  wxPanel:connect(Panel, command_button_clicked),

  {Frame, Text1, Text2}.

loop(State) ->
  {Frame, Text1, Text2} = State,
  receive
    #wx{event = #wxClose{}} ->
      io:format("~p Closing window ~n", [self()]),
      wxWindow:destroy(Frame),
      ok;
    #wx{id = 101, event = #wxCommand{type = command_button_clicked}} ->
      Msg = wxTextCtrl:getValue(Text2),
      wxTextCtrl:setValue(Text2, []),
      wxTextCtrl:appendText(Text1, [Msg]),
      wxTextCtrl:appendText(Text1, [10]),
      io:format("Sending Message: ~n~p ~n", [Msg]),
      loop(State);
    Msg ->
      io:format("loop default triggered: Got ~n ~p ~n", [Msg]),
      loop(State)

  end.
