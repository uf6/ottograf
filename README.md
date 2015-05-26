# ottograf

Graph format description and transformation prototypical musing to:
 - Experiment with human readable file formats for data with a network structure / graph data.
 - Create a transformation script to convert this to the most used graph formats.

## What?

 - An ```@relation``` hint in JSON-LD to specify what are nodes and edges in a linked data document.
 - A conversion script written in [jq](http://stedolan.github.io/jq/) which transforms this format into a typical node/edge JSON format (that can be used for instance in d3.js)

![](https://docs.google.com/drawings/d/1hYCw-Ft44-wUGr3C8hvCemW4tHZclJOo7iBWOoDOynI/pub?w=682&h=354)

## Why not...

 - Use my own thing
   - Problem : It doesn't stand on the shoulders of the giants that already thought about the issue
   - Solution : Use JSON which is both human readable and easy to parse by machines.

 - Use JSON/GraphJSON/JSonGraph/JSONGraphJSON/GraphJSONGraph...
   - Problem : This require keeping nodes and edges in different places in the file, this doesn't scale cognitively, and the document don't reflect the structure that the analyst is trying to model.
   - Solution : Use a format which is more expressive, and allows to spot easily meaningful sentences like ```"Jun"``` ```"knows"``` ```"Elf"```. Linked Data should be very expressive and help with other aspects like linking data between different providers.

 - Use JSON-LD.
   - Problem : Using an linked data approach to model "graph data structures" (like influence mapping networks or corporate structures) has the problem of drowning "significant network relations" into the "noise" of the other triples.
   - Solution : Create a "Graph-JSON-LD" format that would help distinguish regular triples, from actual "links" between entities.

 - Use "Graph-JSON-LD"
   - Problem : It doesn't exist (AFAIK). No graph data viz or analytics package uses this type of format. They all use nodes/edges.
   - Solution : Create this repo to write a proof of concept format and transformation from "Graph-JSON-LD" to the nodes/edges JSON format.

Benefits:
 - This conceptually bridges things like Neo4j (which distinguishes property on nodes, from links between nodes) with Linked Data (for which everything is a "link" i.e. a triple).
 - This provides a proof of concept that the resulting format is human readable and that a simple transformation can be used to create node/edges formats that are widely in use in graph visualisation packages. 
 - And, at least for the author, it seems like a much more usable and natural way to represent a graph structure in text format so it might be the case for analysts.

## How?

Requirements: 
 - [jq 1.4](http://stedolan.github.io/jq/download/)

Usage:
 - ```git clone https://github.com/uf6/ottograf.git```
 - ```cd ottograf; ./transform.sh data.jsonld data.json```

Install
 - ```ln transform.sh /usr/local/bin/ottograf```

Using a ```"@relation"``` boolean attribute in the JSON-LD ```@context``` specifies which attributes are actual "network relations" as opposed to other predicates. In the example below, an foaf representation application could represent the ```knows``` relations as edges in a visualisation while the other predicates (```name```, ```mail```, or any other without the ```"@relation": true``` hint...), would be displayed as a property of the ```"node"``` in the visualisation.

## Example 

 - JSON-LD

```json
{
  "@context": {
    "name": "http://xmlns.com/foaf/0.1/name",
    "knows": { 
      "@id": "http://xmlns.com/foaf/0.1/knows",
      "@relation": true
    }
  },
  "@id": "http://iilab.org/#jun",
  "name": "Jun Matsushita",
  "mail": "jun@iilab.org",
  "knows": [
    {
      "@id" : "pudo",
      "name": "Friedrich Lindenberg"
    },
    {
      "@id": "https://wwelves.org/perpetual-tripper",
      "name": "Elf Pavlik"
    }
  ]
}
```

Note that the ```@context``` property is the key to JSON-LD as it helps describe the data and serves as a way to share a common understanding of what that data is about. Something interesting to note is that it can be served in its own file to make things even more readable (once the analyst have settled on a specific data model). So the above could be simplified as ```"@context" : "http://example.org/mymode.jsonld"``` (or even automatically served by the web server itself so that it doesn't need to be in the JSON file itself).

Also the ```@id``` property could be thought of as the property that enables the unique identification of resources, which is the key to linked data. It allows others to refer to your data, enrich it, link to it, the way that the WWW has allowed this with document. With Linked Data you can do this with your data as well.

[A simple video tutorial about JSON-LD](https://www.youtube.com/watch?v=vioCbTo3C-4)

 - Resulting JSON

```json
{
  "directed": "true",
  "graph": [],
  "nodes": [
    {
      "id": "http://iilab.org/#jun",
      "mail": "jun@iilab.org",
      "name": "Jun Matsushita"
    },
    {
      "id": "https://wwelves.org/perpetual-tripper",
      "name": "Elf Pavlik",
      "type": "knows"
    },
    {
      "id": "pudo",
      "name": "Friedrich Lindenberg",
      "type": "knows"
    }
  ],
  "links": [
    {
      "source": 0,
      "type": "knows",
      "target": 2
    },
    {
      "source": 0,
      "type": "knows",
      "target": 1
    }
  ]
}
```

## TODO

 - Write tests.
 - Make it easy to generate slightly different versions for GraphJSON/JSonGraph/JSONGraphJSON/GraphJSONGraph (specifically d3.js / sigma.js / GEXF /...).
 - Do comparison on merits of different GraphJSON/JSonGraph/JSONGraphJSON/GraphJSONGraph formats.
 - Deal with both arrays of @link attributes and single IRI case.
 - Validate JSON-LD before transforming to GraphJSON
 - Discuss with more LD savvy people how to extend JSON-LD properly ("@link" feels a bit too upstream)
 - Make it easy for analysts to subclass "@link" in a way that helps model different types of links (@influence, @ownership,...) while keeping interoperability and supporting collaboration or convergence towards shared data models. (And enable linked data experts to link back to the appropriate existing work on ontologies that already exists).
 - Create vi/emacs/sublime/textmate/... syntax highlighting variation to help visually differentiate non @link attributes from @link attributes.
 - Error messages.
