-module(chat_room_sup).
-behaviour(supervisor).

%% API
-export([start_link/0, start_room/1]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% This is how we dynamically spawn a room now
start_room(RoomName) ->
    %% supervisor:start_child takes the supervisor name and the argument(s) 
    %% to append to the start_link function defined in the ChildSpec template.
    supervisor:start_child(?SERVER, [RoomName]).

init([]) ->
    SupFlags = #{
        strategy => simple_one_for_one, %% This makes it a dynamic supervisor
        intensity => 3,
        period => 5
    },

    %% For simple_one_for_one, you define a single "template" child spec.
    %% Notice we leave the arguments list empty `[]` because RoomName 
    %% will be passed dynamically via start_room/1 above.
    RoomTemplate = #{
        id => chat_room,
        start => {chat_room, start_link, []}, 
        restart => transient,
        type => worker,
        modules => [chat_room]
    },

    {ok, {SupFlags, [RoomTemplate]}}.