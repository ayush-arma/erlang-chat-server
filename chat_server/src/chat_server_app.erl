%%%-------------------------------------------------------------------
%% @doc chat_server public API
%% @end
%%%-------------------------------------------------------------------

-module(chat_server_app).

-behaviour(application).

-export([start/2, stop/1]).

start(StartType, StartArgs) ->
    io:format("StartType=~p , StartArgs=~p,~n",[StartType,StartArgs]),
    chat_server_sup:start_link().

stop(State) ->
    io:format("Stopping, State=~p~n",[State]),
    ok.

%% internal functions
