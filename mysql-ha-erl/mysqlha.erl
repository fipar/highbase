-module(mysqlha).

-export([start/0,checkService/4,slave/0,restartService/2]).


%
% checks the availability of a MySQL server using
% the external mysql.monitor
%
checkService(User,Password,Database,Host) ->
	Mysql = os:find_executable("mysql"),
	if
		Mysql == false ->
			{badarg, "Couldn't find mysql in the PATH"};
		true ->
			{ExitCode,Output} = tabli:command(Mysql++" -u"++User++" -p"++Password++" -h"++Host++" -e 'select @@version' "++Database),
			case ExitCode of
				0 ->
					{ok, ExitCode, lists:flatten(Output)};
				1 ->
					{error, ExitCode, lists:flatten(Output)}
			end
	end.


%
%
%
takeover(Config) ->
	ClusterDevice = config:get_val("CLUSTER_DEVICE",Config),
	ClusterIp = config:get_val("CLUSTER_IP",Config),
	%tabli:command(" should we run an external script or learn how to do this in erlang??  "),
	% for the first release, we'll rely on an external command. write scripts to handle everything and add yet another
	% config parameter to specify where the hell we're installed
	io:format("someday, i'll be configuring ~p as the primary address for ~p",[ClusterIp,ClusterDevice]),
	true.

%
% executes Sudo InitScript restart
% this is remotely invoked
restartService(Invoker, InitScript) ->
	Sudo = os:find_executable("sudo"),
	if
		Sudo == false ->
			{badarg, "Couldn't find sudo in the PATH"};
		true ->
			{ExitCode,Output} = tabli:command(Sudo++" "++InitScript++" restart"),
			case ExitCode of
				0 ->
					Invoker ! {self(),ok};
				1 ->
					Invoker ! {self(),Output}
			end
	end.


% update this value with new keys
wait_for_config(_,30) ->
	true;



wait_for_config(Config,N) ->
	receive 
		{config, Var, Val} ->
			wait_for_config([{Var,Val}|Config],N+1);
		{config_end} ->
			Config
	after 350 ->
		Config
	end.



%
% entry point for this module
% 
start() ->
	spawn(config,load_config,[self()]),
	Config = wait_for_config([],0),
	User = config:get_val("DB_USER",Config),
	Password = config:get_val("DB_PASSWORD",Config),
	Database = config:get_val("MYSQL_DATABASE",Config),
	Master = config:get_val("MASTER",Config),
	SlaveNode = config:get_val("SLAVE_ERL_NODE",Config),
	{Status,Output} = tabli:safe_invoke_monitor(SlaveNode,mysqlha,checkService,[User,Password,Database,Master],1500),
	case Status of
		ok ->
			io:format("checkService returned ok (~p)~n",[Output]);
		error ->
			io:format("checkService returned error! (~p)~n",[Output]);
		timeout ->
			io:format("checkService returned timeout! (~p)~n",[Output]);
		nodedown ->
			io:format("checkService returned nodedown!~n");
		_ ->
			io:format("checkService returned: ~p,~p~n",[Status,Output])
	end.



%
% checks mysqld on the master node
%
check_master(Config) ->
	User = config:get_val("DB_USER",Config),
	Password = config:get_val("DB_PASSWORD",Config),
	Database = config:get_val("MYSQL_DATABASE",Config),
	Master = config:get_val("MASTER",Config),
	Threshold = config:get_time_val(config:get_val("MONITOR_CHK_THRESHOLD",Config)),
	MasterNode = list_to_atom(config:get_val("MASTER_ERL_NODE",Config)),
	{Status,Output} = tabli:safe_invoke_monitor(MasterNode,mysqlha,checkService,[User,Password,Database,Master],Threshold,true),
	case Status of
		ok ->
			{Result,_,Message} = Output,
			if
				Result == ok ->
					{ ok, Message };
				true ->
					{ error, Message }
			end;
		error ->
			{ invoke_error, Output };	
		timeout ->
			{ timeout, Output};	
		nodedown ->
			{ error, nodedown};	
		_ ->
			{ Status,Output}
	end.


%
% Attempts to restart mysqld on the master node
% It returns the atom success ONLY if after running sudo InitScript restart on MasterNode, 
% check_master returns ok

%
% TODO: This is broken, sometimes, the service will be restarted successfully, but this won't
% be properly detected, even with the nested checks. This is hard to debug, since it's a timing condition. 
% _PERHAPS_ it can be fixed just with clever use of the time thresholds
%
% it seems fixed with the MONITOR_WAIT_THRESHOLD hack
attempt_restart(Config) ->
	InitScript = config:get_val("INIT_SCRIPT",Config),
	MasterNode = list_to_atom(config:get_val("MASTER_ERL_NODE",Config)),
	Peer = spawn(MasterNode,mysqlha,restartService,[self(),InitScript]),
	Threshold = config:get_time_val(config:get_val("MONITOR_CHK_THRESHOLD",Config)),
	WaitThreshold = config:get_time_val(config:get_val("MONITOR_WAIT_THRESHOLD",Config)),
	receive
		{Peer,ok} ->
			tabli:sleep(WaitThreshold), % we sleep before double checking
			{RC, _ } = check_master(Config), 
			if 
				RC == ok ->
					Result = success;
				true ->
					tabli:sleep(Threshold),
					{RC0, _ } = check_master(Config),
					if
						RC0 == ok ->
							Result = success;
						true ->
							Result = failure
					end 
			end;
		{Peer,_} ->
			Result = failure;
		_ ->
			Result = failure
		after Threshold ->
			Result = failure
	end,
	Result.

%
% Slave routine
%
slave() ->
	io:format("running slave.. ~n"),
	spawn(config,load_config,[self()]),
	Config = wait_for_config([],0),
	SleepTime = config:get_time_val(config:get_val("SLAVE_SLEEP_TIME",Config)),
	{ Result, Message } = check_master(Config),
	if
		Result == ok ->
			tabli:sleep(SleepTime),
			slave();
		Result == error ->
			if
				Message == nodedown ->
					io:format("attempting takeover after nodedown message~n"),
					takeover(Config); % if the node is down, we do a straight takeover
				true ->
					% TODO: we should first attempt to restart MySQL on the remote node
					io:format("attempting restart after error message~n"),
					RestartResult = attempt_restart(Config),
					if 
						RestartResult == success ->
							io:format("restart succeeded~n"),
							slave(); % if we succeded restarting the remote mysqld, we keep running the slave routine
						true ->
							io:format("restart failed, attempting failover~n"),	
							FailoverResult = failover(),
							if 
								FailoverResult == success ->
									io:format("attempting simple takeover~n"),
									takeover(Config);
								true ->
									io:format("attempting takeover with arp spoofing~n"),
									arp_spoof(),
									takeover(Config)
							end
					end
			end 
	end.



arp_spoof() ->
	true.


failover() ->
	true.


