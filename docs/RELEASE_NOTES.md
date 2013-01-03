Yokozuna Release Notes
==========

0.2.0
----------

This is the second pre-release of Yokozuna.

### Active Anti-Entropy

[Active Anti-Entropy][yz_aae] is a background process which constantly
seeks out divergence between Riak data and indexes stored by Yokozuna.
This process is made efficient by the use of hashtrees which are
updated as data comes in.  In the case were there is little to no
divergence the work performed is unnoticeable.  When divergence is
detected [read-repair][rr] is invoked and re-indexing occurs.

[rr]: http://docs.basho.com/riak/latest/references/appendices/concepts/Riak-Glossary/#Read-Repair

[yz_aae]: https://github.com/rzezeski/yokozuna/commit/7a32c6fce7b3d30de0f5f3f0d7a9a6ac29460f9f

### Sibling Support

Eric Redmond added [sibling support][yz_4].  Now, when [allow_mult][]
is enabled and siblings occur Yokozuna will index all object versions.
Likewise, when siblings are resolved the obsolete indexes will be
cleaned up.

[allow_mult]: http://docs.basho.com/riak/latest/references/appendices/concepts/Vector-Clocks/#Siblings

[yz_4]: https://github.com/rzezeski/yokozuna/pull/4

### Auto-Suffix JSON Extractor

Dan Reverri added a [JSON extractor][yz_16] that automatically adds
type suffixes to each field.  This allows you to use the default
schema with existing data.  That is, you don't have to create a custom
schema or add field suffixes yourself.

[yz_16]: https://github.com/rzezeski/yokozuna/pull/16

### Benchmark Scripts

A collection of scripts have been created under `misc/bench/bin`.
They are used for automating the process of running benchmarks with
Basho Bench, collecting various metrics, transforming the raw data,
and finally visualizing it via d3js.  Currently these scripts assume
the target cluster is running on SmartOS.  The driver scripts,
i.e. the scripts that run the benchmark, have only been tested on OSX.

### Misc

* Use semver rebar plugin ([3bff0c][]).

* Fix type issue in JSON extractor ([f2d798][]).

* Allow POST select ([yz_23][]).

* Send/Return Solr Headers ([yz_29][]).

* Remove shell wrapper around JVM ([yz_18][]).

* Remove unused files from included Solr distribution ([ab1303][]).

[3bff0c]: https://github.com/rzezeski/yokozuna/commit/3bff0c3a1407f5054838437ba534ae422c9d3bb5

[ab1303]: https://github.com/rzezeski/yokozuna/commit/ab130361f36e0f2f1b1307d5b99060a2c01d5648

[f2d798]: https://github.com/rzezeski/yokozuna/commit/f2d798c25b43dad820bdde7995c4219a2d892622

[yz_18]: https://github.com/rzezeski/yokozuna/issues/18

[yz_23]: https://github.com/rzezeski/yokozuna/issues/23

[yz_29]: https://github.com/rzezeski/yokozuna/issues/29


0.1.0
----------

This is the first pre-release of Yokozuna.  It provides automatic
distribution and replication of Solr indexes.  It integrates with Riak
KV providing near-real-time indexing of KV objects as they are
written.  Following are some of the major features included in this
release.

### Tight Integration With Solr

Yokozuna comes pre-bundled with Solr 4.0.0 running in the Jetty
container.  Yokozuna handles the basic administration of Solr such as
starting and stopping Solr, creating Cores, sharding the documents,
replicating the documents, and performing distributed queries.

To the client Yokozuna acts as a single Solr instance.  Queries are
sent to Yokozuna the same as a single Solr instance.  Yokozuna
determines which shards need to be contacted and performs a
distributed Solr query.  The results are returned verbatim to the
client.  This means if [Solr distributed search][sds] supports it then
Yokozuna supports it.  Furthermore, existing Solr clients may be used
to query Yokozuna.  There is a [simple example][se] of using the SolrJ
client.

### Administration of Indexes via HTTP

To start indexing KV data an index must be created and a hook
installed on the bucket.  This can be done in one step via HTTP.
Learn more at [ADMIN.md][admin].

### Text, XML and JSON Extractors

Before Yokozuna can index a KV object it must first convert it to a
Solr document.  This release includes support for text, XML and JSON.
To see how Yokozuna is extracting data the HTTP extract resource can
be used for testing.  It returns the field-value pairs in JSON format.

    curl -XPUT -H 'content-type: application/json' 'http://localhost:8098/extract' -d '...SOME JSON...' | jsonpp

### Tagging

Tagging is the ability to add indexes via Riak KV metadata.  This is
useful when storing binary data or for indexing data about the data.
More information can be found in [TAGGING.md][tagging].

### EC2 Support

A Yokozuna AMI is provided to make it easier to try.  More information
can be be found in [EC2.md][ec2].

[admin]: https://github.com/rzezeski/yokozuna/blob/7abbc3f7430373a58fdefaa65731759344e86cc7/docs/ADMIN.md

[ec2]: https://github.com/rzezeski/yokozuna/blob/7abbc3f7430373a58fdefaa65731759344e86cc7/docs/EC2.md

[sds]: http://wiki.apache.org/solr/DistributedSearch#Distributed_Searching_Limitations

[se]: https://github.com/rzezeski/yokozuna/blob/7abbc3f7430373a58fdefaa65731759344e86cc7/priv/java/com/basho/yokozuna/query/SimpleQueryExample.java

[tagging]: https://github.com/rzezeski/yokozuna/blob/7abbc3f7430373a58fdefaa65731759344e86cc7/docs/TAGGING.md