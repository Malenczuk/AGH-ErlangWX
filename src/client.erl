%%%-------------------------------------------------------------------
%%% @author mdronski
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. Jun 2018 22:21
%%%-------------------------------------------------------------------
-module(client).
-author("mdronski").

-behaviour(application).

%% Application callbacks
-export([start/2, register/1, sendMessage/2, loop/1,
  stop/1]).

%%%===================================================================
%%% Application callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application is started using
%% application:start/[1,2], and should start the processes of the
%% application. If the application is structured according to the OTP
%% design principles as a supervision tree, this means starting the
%% top supervisor of the tree.
%%
%% @end
%%--------------------------------------------------------------------
-spec(start(StartType :: normal | {takeover, node()} | {failover, node()},
    StartArgs :: term()) ->
  {ok, pid()} |
  {ok, pid(), State :: term()} |
  {error, Reason :: term()}).
start(_StartType, _StartArgs) ->
  ets:new(pid_table, [named_table, protected, set, {keypos, 1}]),
  case server:start_link() of
    {ok, Pid} ->
      {ok, Pid};
    Error ->
      Error
  end.

register(Username) ->
  Pid = spawn(?MODULE, loop, [Username]),
  ets:insert(pid_table, {Username, Pid}),
  gen_server:call(server, {register, Pid, Username}).

sendMessage(Username, Message) ->
  [{Username, Pid}] = ets:lookup(pid_table, Username),
  Pid ! {send, Message}.

loop(Username) ->
  receive
    {send, Message} ->
      gen_server:call(server, {send_message, Username, Message}),
      loop(Username);
    {print, User, Message} ->
      io:format("~s: ~s~n", [User, Message]),
      loop(Username)
  end,
  ok.



%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called whenever an application has stopped. It
%% is intended to be the opposite of Module:start/2 and should do
%% any necessary cleaning up. The return value is ignored.
%%
%% @end
%%--------------------------------------------------------------------
-spec(stop(State :: term()) -> term()).
stop(_State) ->
  ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
