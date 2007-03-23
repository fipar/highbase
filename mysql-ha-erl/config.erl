-module(config).

-export([load_config/1,get_val/2,get_time_val/1,inspect/1]).

%
% todo: add security
%       - this should be a registered process, and our registered name should be sent along with the message tuple
send_tokens([Var,Val|_],Client) ->
	Client ! { config, Var, Val }.

%
% retrieve a value from the config list
%

get_val(_,[]) ->
	true;

get_val(SearchedVar,[{Var,Val}|Rest]) ->
	if
		SearchedVar == Var ->
			Val;
		true ->
			get_val(SearchedVar,Rest)
	end.


%
% These process a time value and return something usable for tabli:safe_invoke, safe_invoke_remote
%

get_time_val(Val) when number(Val) ->
	Val * 1000;

get_time_val(Val) ->
	MatchRes = regexp:match(Val,"[Mm][Ss]"),
	if 
		MatchRes /= nomatch ->
			{match,Start,_} = MatchRes,
			inspect([Start]),
			list_to_integer(string:strip(string:substr(Val,1,Start-1)));	
		true ->
			MR = regexp:match(Val,"[0-9][0-9]*"),
			if
				MR /= nomatch ->
					list_to_integer(Val) * 1000;
				true ->
					{error, "The erlang version only supports time values specified in seconds (no units) or milliseconds (ms)"}
			end
	end.


inspect([]) ->
	true;

inspect([H|T]) ->
	io:format("~p~n",[H]),
	inspect(T).

%
% These traverse the Tokens list, discarding comments and blank lines, and invoking send_tokens for every other (presumably valid) line
% No validation is performed on the file


parse_tokens([],Client) ->
	Client ! { config_end };

parse_tokens([Token|Tokens],Client) ->
	MatchRes = regexp:match(Token,"(^#.*|^$)"),
	if 
		MatchRes /= nomatch ->
			parse_tokens(Tokens,Client); % ignore comments and blank lines
		true ->
			TK = string:tokens(Token,"="),
			send_tokens(TK,Client),
			parse_tokens(Tokens,Client)
	end.
%
% Client is the Pid of the calling client
load_config(Client) when pid(Client) ->
	{Status, Binary} = file:read_file("/etc/mysql-ha.conf"),
	if
		Status == error ->
			io:format("Could not read config file. Reason: ~p~n",[Binary]);
		Status /= error ->
			Tokens = string:tokens(binary_to_list(Binary),"\n"),
			parse_tokens(Tokens,Client)
	end.


