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
    | { source   : ( [ $nodes[] | .id ]| index($id) )
      , type : $link
      , target   : ( .["@id"] as $target | [ $nodes[] | .id ]| index($target) )
      } ]
  ] | map(select(length !=0)) 
    | reduce .[] as $item ( [] 
                          ; . + $item )
    | . as $edges 
| { directed: "true"
  , graph: []
  , nodes: $nodes
  , links: $edges 
  }