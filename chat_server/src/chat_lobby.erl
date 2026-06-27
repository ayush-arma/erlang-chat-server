-module(chat_lobby).
-behaviour(gen_server).

%% API
-export([start_link/0, create_room/1, delete_room/1, list_rooms/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% CRITICAL: In Phase 3, rooms is a MAP (#{}) tracking RoomName => Pid
-record(state, {rooms = #{}}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

create_room(RoomName) ->
    gen_server:call(?MODULE, {create_room, RoomName}).

delete_room(RoomName) ->
    gen_server:call(?MODULE, {delete_room, RoomName}).

list_rooms() ->
    gen_server:call(?MODULE, list_rooms).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{rooms = #{}}}.

handle_call({create_room, RoomName}, _From, State) ->
    %% Correct Map-based check instead of lists:member
    case maps:is_key(RoomName, State#state.rooms) of
        true ->
            {reply, {error, exists}, State};
        false ->
            %% Dynamically start the process using our corrected simple_one_for_one supervisor
            case chat_room_sup:start_room(RoomName) of
                {ok, Pid} ->
                    NewRooms = maps:put(RoomName, Pid, State#state.rooms),
                    {reply, {ok, Pid}, State#state{rooms = NewRooms}};
                Error ->
                    {reply, {error, Error}, State}
            end
    end;
handle_call({delete_room, RoomName}, _From, State) ->
    case maps:find(RoomName, State#state.rooms) of
        {ok, Pid} ->
            exit(Pid, shutdown),
            NewRooms = maps:remove(RoomName, State#state.rooms),
            {reply, ok, State#state{rooms = NewRooms}};
        error ->
            {reply, {error, not_found}, State}
    end;
handle_call(list_rooms, _From, State) ->
    RoomNames = maps:keys(State#state.rooms),
    {reply, RoomNames, State};
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
