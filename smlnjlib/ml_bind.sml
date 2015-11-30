
fun use' file = use ("smlnjlib/" ^ file)

val _ = app use'
    [ "lib-base-sig.sml"
    , "lib-base.sml"
    , "random-sig.sml"
    , "random.sml"
    ]

