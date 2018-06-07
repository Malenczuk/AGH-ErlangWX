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

%% updated version of wxcd08, by Alan Gingras
%% resolves exiting during mid-run
-compile(export_all).
-include_lib("wx/include/wx.hrl").
-export([start/0]).

start() ->
  State = make_window(),
  ok.

make_window() ->
  Server = wx:new(),
  Frame = wxFrame:new(Server, -1, "Messenger", [{size,{400, 600}}]),
  Panel  = wxScrolledWindow:new(Frame),
  wxScrolledWindow:enableScrolling(Panel, false, true),

  MainSizer =  wxBoxSizer:new(?wxVERTICAL),
  MainSizer2 =  wxBoxSizer:new(?wxVERTICAL),
  wxPanel:setSizer(Panel, MainSizer),





  Text1 = wxTextCtrl:new(Panel, 1001, [{style, ?wxTE_MULTILINE}, {style, ?wxTE_NO_VSCROLL}, {size, {200, 75}}]),
  Text2 = wxTextCtrl:new(Panel, 1001, [{style, ?wxTE_MULTILINE}, {style, ?wxTE_NO_VSCROLL}, {size, {200, 200}}]),
  wxTextCtrl:setEditable(Text2, false),

  wxSizer:add(MainSizer, Text2, [{flag, ?wxEXPAND}]),
  wxSizer:addSpacer(MainSizer, 50),
  wxSizer:add(MainSizer, Text1, [{flag, ?wxEXPAND}, {flag, ?wxALIGN_CENTER_VERTICAL}]),


  wxFrame:show(Frame),

  wxFrame:connect( Frame, close_window),
  wxPanel:connect(Panel, command_button_clicked).

