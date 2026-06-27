-module(chat_room).
-behaviour(gen_server).

-export([start_link/1, get_name/1]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {name}).

start_link(RoomName) ->
    gen_server:start_link(?MODULE, [RoomName], []).

get_name(Pid) ->
    gen_server:call(Pid, get_name).

init([RoomName]) ->
    {ok, #state{name = RoomName}}.

handle_call(get_name, _From, State) ->
    {reply, State#state.name, State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_call}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.