%% -------------------------------------------------------------------
%%
%% Copyright (c) 2012 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
%%
%% @doc This module contains functionality related to integrating with
%%      Riak KV.

-module(yz_kv).
-compile(export_all).
-include("yokozuna.hrl").

-define(ONE_SECOND, 1000).
-define(WAIT_FLAG(Index), {wait_flag, Index}).
-define(MAX_WAIT_FOR_INDEX, app_helper:get_env(?YZ_APP_NAME, max_wait_for_index_seconds, 5)).

-type check() :: {module(), atom(), list()}.
-type seconds() :: pos_integer().
-type write_reason() :: handoff | put.


%%%===================================================================
%%% API
%%%===================================================================

%% @doc An object modified hook to create indexes as object data is
%% written or modified.
%%
%% NOTE: This code runs on the vnode process.
-spec index(riak_object:riak_object(), write_reason(), term()) -> ok.
index(Obj, Reason, VNodeState) ->
    {ok, Ring} = riak_core_ring_manager:get_my_ring(),
    {Bucket, _} = BKey = {riak_object:bucket(Obj), riak_object:key(Obj)},
    ok = maybe_wait(Reason, Bucket),
    BProps = riak_core_bucket:get_bucket(Bucket, Ring),
    NVal = riak_core_bucket:n_val(BProps),
    Idx = riak_core_util:chash_key(BKey),
    IdealPreflist = riak_core_ring:preflist(Idx, NVal, Ring),
    FPN = ?INT_TO_BIN(first_partition(IdealPreflist)),
    Partition = ?INT_TO_BIN(get_partition(VNodeState)),
    Doc = yz_doc:make_doc(Obj, FPN, Partition),
    ok = yz_solr:index(binary_to_list(Bucket), [Doc]).

%% @doc Install the object modified hook on the given `Bucket'.
-spec install_hook(binary()) -> ok.
install_hook(Bucket) when is_binary(Bucket) ->
    Mod = yz_kv,
    Fun = index,
    ok = riak_kv_vnode:add_obj_modified_hook(Bucket, Mod, Fun).


%%%===================================================================
%%% Private
%%%===================================================================

%% @private
%%
%% @doc Determine whether process `Flag' is set.
-spec check_flag(term()) -> boolean().
check_flag(Flag) ->
    true == erlang:get(Flag).

%% @private
%%
%% @doc Get first partition from a preflist.
first_partition([{Partition, _}|_]) ->
    Partition.

%% @private
%%
%% @doc Get the partition from the `VNodeState'.
get_partition(VNodeState) ->
    riak_kv_vnode:get_state_partition(VNodeState).

%% @private
%%
%% @doc Wait for index creation if hook was invoked for handoff write.
-spec maybe_wait(write_reason(), binary()) -> ok.
maybe_wait(handoff, Bucket) ->
    Index = binary_to_list(Bucket),
    Flag = ?WAIT_FLAG(Index),
    case check_flag(Flag) of
        false ->
            Seconds = ?MAX_WAIT_FOR_INDEX,
            ok = wait_for({yz_solr, ping, [Index]}, Seconds),
            ok = set_flag(Flag);
        true ->
            ok
    end;
maybe_wait(_, _) ->
    ok.

%% @doc Set the `Flag'.
-spec set_flag(term()) -> ok.
set_flag(Flag) ->
    erlang:put(Flag, true),
    ok.

%% @doc Wait for `Check' for the given number of `Seconds'.
-spec wait_for(check(), seconds()) -> ok.
wait_for(_, 0) ->
    ok;
wait_for(Check={M,F,A}, Seconds) when Seconds > 0 ->
    case M:F(A) of
        true ->
            ok;
        false ->
            timer:sleep(?ONE_SECOND),
            wait_for(Check, Seconds - 1)
    end.