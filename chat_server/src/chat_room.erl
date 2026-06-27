-module(chat_room).
-behaviour(gen_server).

%% API
-export([start_link/1, get_name/1, join/1, leave/1, broadcast/2, history/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% Phase 4 State Structure
-record(state, {
    name,
    %% List of PIDs
    users = [],
    %% List of strings/messages
    history = []
}).

%%%===================================================================
%%% API
%%%===================================================================

start_link(RoomName) ->
    gen_server:start_link(?MODULE, [RoomName], []).

get_name(Pid) ->
    gen_server:call(Pid, get_name).

join(Pid) ->
    %% self() gets the PID of whoever is calling this function (the user)
    gen_server:call(Pid, {join, self()}).

leave(Pid) ->
    gen_server:call(Pid, {leave, self()}).

broadcast(Pid, Message) ->
    gen_server:call(Pid, {broadcast, self(), Message}).

history(Pid) ->
    gen_server:call(Pid, history).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([RoomName]) ->
    {ok, #state{name = RoomName, users = [], history = []}}.

handle_call(get_name, _From, State) ->
    {reply, State#state.name, State};
handle_call({join, UserPid}, _From, State) ->
    case lists:member(UserPid, State#state.users) of
        true ->
            {reply, {error, already_joined}, State};
        false ->
            NewUsers = [UserPid | State#state.users],
            {reply, ok, State#state{users = NewUsers}}
    end;
handle_call({leave, UserPid}, _From, State) ->
    case lists:member(UserPid, State#state.users) of
        true ->
            NewUsers = lists:delete(UserPid, State#state.users),
            {reply, ok, State#state{users = NewUsers}};
        false ->
            {reply, {error, not_in_room}, State}
    end;
handle_call({broadcast, SenderPid, Message}, _From, State) ->
    FormattedMsg = {chat_msg, State#state.name, SenderPid, Message},

    %% Send the message asynchronously to every user process in the room
    lists:foreach(
        fun(UserPid) ->
            UserPid ! FormattedMsg
        end,
        State#state.users
    ),

    %% Save the message to history (appending to the end of the list)
    NewHistory = State#state.history ++ [FormattedMsg],
    {reply, ok, State#state{history = NewHistory}};
handle_call(history, _From, State) ->
    {reply, State#state.history, State};
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
