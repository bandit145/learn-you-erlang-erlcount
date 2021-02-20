-module(erlcount_lib).
-export([find_erl/1, regex_count/2]).
-include_lib("kernel/include/file.hrl").

%%finds all files ending in .erl.

find_erl(Directory) ->
	find_erl(Directory, queue:new()).

regex_count(Re, Str) ->
	case re:run(Str, Re, [global]) of
		notmatch -> 0;
		{match, List} -> length(List)
	end.

%%private
%%dispatches based on file type

find_erl(Name, Queue) ->
	{ok, F = #file_info{}} = file:read_file_info(Name),
	case F#file_info.type of
		directory -> handle_directory(Name, Queue);
		regular -> handle_regular_file(Name, Queue);
		_Other -> dequeue_and_run(Queue)
	end.

%%checks if file finishes in erl

handle_regular_file(Name, Queue) ->
	case filename:extension(Name) of
		".erl" ->
			{continue, Name, fun() -> dequeue_and_run(Queue) end};
		_NonErl ->
			dequeue_and_run(Queue)
	end.

handle_directory(Dir, Queue) ->
	case file:list_dir(Dir) of
		{ok, []} ->
			dequeue_and_run(Queue);
		{ok, Files} ->
			dequeue_and_run(enqueu_many(Dir, Files, Queue))
	end.

%%pops and item form the queue and runs it.

dequeue_and_run(Queue) ->
	case queue:out(Queue) of
		{empty, _} -> done;
		{{value, File}, NewQueue} -> find_erl(file, NewQueue)
	end.

%% add a bunch of items to the queue

enqueu_many(Path, Files, Queue) ->
	F = fun(File, Q) -> queue:in(filename:join(Path,File), Q) end,
	lists:foldl(F, Queue, Files).

