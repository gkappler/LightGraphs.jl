function show(io::IO, g::DiGraph)
    if nv(g) == 0
        print(io, "empty directed graph")
    else
        print(io, "{$(nv(g)), $(ne(g))} directed graph")
    end
end

function DiGraph(n::Int)
    fadjlist = Vector{Vector{Int}}()
    badjlist = Vector{Vector{Int}}()
    for i = 1:n
        push!(badjlist, Vector{Int}())
        push!(fadjlist, Vector{Int}())
    end
    return DiGraph(1:n, Set{Edge}(), badjlist, fadjlist)
end

DiGraph() = DiGraph(0)

function DiGraph{T<:Real}(adjmx::SparseMatrixCSC{T})
    dima, dimb = size(adjmx)
    isequal(dima,dimb) || error("Adjacency / distance matrices must be square")

    g = DiGraph(dima)
    maxc = length(adjmx.colptr)
    for c = 1:(maxc-1)
        for rind = adjmx.colptr[c]:adjmx.colptr[c+1]-1
            isnz = (adjmx.nzval[rind] != zero(T))
            if isnz
                r = adjmx.rowval[rind]
                add_edge!(g,r,c)
            end
        end
    end
    return g
end

function DiGraph{T<:Real}(adjmx::AbstractMatrix{T})
    dima,dimb = size(adjmx)
    isequal(dima,dimb) || error("Adjacency / distance matrices must be square")

    g = DiGraph(dima)
    for i in find(adjmx)
        ind = ind2sub((dima,dimb),i)
        add_edge!(g,ind...)
    end
    return g
end

function DiGraph(g::Graph)
    h = DiGraph(nv(g))
    for e in edges(g)
        push!(h.edges,e)
        push!(h.edges,reverse(e))
    end
    h.fadjlist = copy(fadj(g))
    h.badjlist = copy(badj(g))
    return h
end

badj(g::DiGraph) = g.badjlist
badj(g::DiGraph, v::Int) = badj(g)[v]

function copy(g::DiGraph)
    return DiGraph(g.vertices,copy(g.edges),deepcopy(g.fadjlist),deepcopy(g.badjlist))
end

is_directed(g::DiGraph) = true

function add_edge!(g::DiGraph, e::Edge)
    s, d = e
    s in vertices(g) || error("Vertex $s not in graph")
    d in vertices(g) || error("Vertex $d not in graph")
    _insert_and_dedup!(g.fadjlist[s], d)
    _insert_and_dedup!(g.badjlist[d], s)
    push!(g.edges, e)
    return e
end


function rem_edge!(g::DiGraph, e::Edge)
    has_edge(g,e) || error("Edge $e is not in graph")
    i = searchsorted(g.fadjlist[src(e)], dst(e))[1]
    deleteat!(g.fadjlist[src(e)], i)
    i = searchsorted(g.badjlist[dst(e)], src(e))[1]
    deleteat!(g.badjlist[dst(e)], i)
    return pop!(g.edges, e)
end


function add_vertex!(g::DiGraph)
    g.vertices = 1:nv(g)+1
    push!(g.badjlist, Vector{Int}())
    push!(g.fadjlist, Vector{Int}())

    return nv(g)
end


has_edge(g::DiGraph, e::Edge) = e in edges(g)

degree(g::DiGraph, v::Int) = indegree(g,v) + outdegree(g,v)
"Returns all the vertices which share an edge with `v`."
all_neighbors(g::DiGraph, v::Int) = union(in_neighbors(g,v), out_neighbors(g,v))
density(g::DiGraph) = ne(g) / (nv(g) * (nv(g)-1))
