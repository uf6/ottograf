. as $all
| .["@context"] as $context 
  | $context 
  | to_entries 
  | map(select(.value | .["@relation"]? == true)) 
  | [ .[].key ] as $links 
| $all 
  | del(.["@context"]) 
  | to_entries 
  | map(select( [.key] as $keys 
              | $links 
              | contains($keys) 
              | not )) 
  | from_entries
  | with_entries(.key |= ( if . == "@id" then "id" else . end )) as $root 
| $all
  | del(.["@context"]) 
  | [ .. 
    | objects
    | to_entries
    | map(select( [.key] as $keys
                | $links 
                | contains($keys)))
    | reduce .[] as $item ( []
                          ; . + ( [ $item.value[] 
                                  | {"type": $item.key } + . 
                                  ] ) )   
    ] | reduce .[] as $item ( [] 
                            ; . + $item )
      | unique_by(.["@id"]) | . as $nodes
| $nodes 
  | [ .[]
    | to_entries 
    | map(select( [.key] as $keys 
                | $links 
                | contains($keys) 
                | not )) 
    | from_entries 
    | with_entries(.key |= ( if . == "@id" then "id" else . end ))
    ] as $nodes 
| ( [ $root ] + $nodes ) as $nodes
| [ $all
  | del(.["@context"])
  | ..
  | .["@id"]? as $id
  | $links[]
  | . as $link
  | $all
  | ..
  | objects
  | select(.["@id"]? == $id)
  | to_entries 
  | map(select( [.key] as $keys 
              | [ $link ] 
              | contains($keys)))
  | [ .[].value[]
    | { ($opt_source)   : ( if ($opt_index == "numeric") then ( [ $nodes[] | .id ]| index($id) ) else ($id) end )
      , type : $link
      , ($opt_target)   : ( if ($opt_index == "numeric") then ( .["@id"] as $target | [ $nodes[] | .id ]| index($target) ) else (.["@id"]?) end)
      } ]
  ] | reduce .[] as $item ( [] 
                          ; . + $item )
    | [ .[] | select( (.from? | length) !=0 ) ] | . as $edges 
| ($opt_graph_prefix | fromjson) 
  * { ($opt_nodes): $nodes
    , ($opt_edges): $edges 
    } 