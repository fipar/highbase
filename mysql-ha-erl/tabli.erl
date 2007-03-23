-module(tabli).

%
% PROTOTYPE
%

%
% The module tabli provides mechanisms for: 
%	- starting processes with a guaranteed timeout (*)
%	- starting and registering servers regardless of their location
%
% (*): the timeout is guaranteed on the response, not on the execution. a process can still linger indefinitely if it's programmed the wrong way


-export([safe_invoke/4,safe_invoke_peer/4,safe_invoke_monitor/5,safe_invoke_monitor/6,command/1,sleep/1]).


%
% run command through a port
% returns {ExitCode,CommandOutput}
%
command(Command) ->
	Opt = [stream, exit_status, use_stdio, stderr_to_stdout, in, eof],
	Port = open_port({spawn, Command}, Opt),
	get_data(Port, []).

%
% helper for command/1
%
get_data(Port,Data) -> 
	receive
		{Port, {data, D1}} ->
			get_data(Port, [D1|Data]);
		{Port, eof} ->
			port_close(Port),
			receive
				{Port, {exit_status, N}} ->
					{N, Data}
			end
	end.


% save_invoke_peer/3
% invoke Fun with Args, and send a message back to 
% my caller when Fun is done
% 	
% Caller		PID of the calling process
% Module/Fun/Args	Standard arguments for apply/3	
safe_invoke_peer(Caller, Module, Fun, Args) when pid(Caller) ->
	case apply(Module, Fun, Args) of
		{'error',Error} ->
			Caller ! { self(), error, Error};
		Other ->
			Caller ! { self(), other, Other}
	end.

	
% attempt to invoke Fun with an assured Timeout for the result
% our Result is a tuple with error/ok/timeout + the reason (if any) or message (if any)  and Function's name and invocation Arguments
safe_invoke(Module, Fun, Args, Timeout) ->
	Peer = spawn(tabli, safe_invoke_peer, [self(), Module, Fun, Args]),
	receive 
		{ Peer, error, Error} ->
			{ error, Error};
		{ Peer, other, Other} ->
			{ ok, Other};
		Other ->
			{ oddity, Other}
	after Timeout ->
		{timeout, "timeout exceeded ("++Timeout++" ms) while waiting for "++Module++":"++Fun}
	end.



% same as safe_invoke, but also wrap the call in a couple of monitor_node invocations
% name is deceiving. This doesn't invoke a remote function, it just wraps
% a local function invocation in a couple of monitor_node/2 invocations..
safe_invoke_monitor(Node,Module, Fun, Args, Timeout) ->
	monitor_node(Node,true),
	Peer = spawn(tabli, safe_invoke_peer, [self(), Module, Fun, Args]),
	receive 
		{ nodedown, Node } ->
			{ nodedown, Node };
		{ Peer, error, Error} ->
			monitor_node(Node,false),
			{ error, Error};
		{ Peer, other, Other} ->
			monitor_node(Node,false),
			{ ok, Other};
		Other ->
			monitor_node(Node,false),
			{ oddity, Other}
	after Timeout ->
			monitor_node(Node,false),
			{timeout, "timeout exceeded ("++Timeout++" ms) while waiting for "++Module++":"++Fun}
	end.


% same as safe_invoke, but also wrap the call in a couple of monitor_node invocations
% name is deceiving. This doesn't invoke a remote function, it just wraps
% a local function invocation in a couple of monitor_node/2 invocations..
safe_invoke_monitor(Node,Module, Fun, Args, Timeout, Ignoredown) ->
	monitor_node(Node,true),
	Peer = spawn(tabli, safe_invoke_peer, [self(), Module, Fun, Args]),
	receive 
		{ nodedown, Node } ->
			if 
				Ignoredown == true ->
					receive
						{ Peer, error, Error }  ->
							{ error, Error};
						{ Peer, other, Other} ->
							{ ok, Other}
					after Timeout ->
						{timeout, "timeout exceeded ("++Timeout++" ms) while waiting for "++Module++":"++Fun}	
					end;
				 true ->
				 	{ nodedown, Node}
			end;
		{ Peer, error, Error} ->
			monitor_node(Node,false),
			{ error, Error};
		{ Peer, other, Other} ->
			monitor_node(Node,false),
			{ ok, Other};
		Other ->
			monitor_node(Node,false),
			{ oddity, Other}
	after Timeout ->
			monitor_node(Node,false),
			{timeout, "timeout exceeded ("++Timeout++" ms) while waiting for "++Module++":"++Fun}
	end.


sleep(Millis) when integer(Millis) ->
	receive 
		after Millis ->
			true
	end.
