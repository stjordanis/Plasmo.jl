#An Optinode nlp_data object just points to the underlying JuMP Model object
function JuMP._init_NLP(node::OptiNode)
    JuMP._init_NLP(node.model)
    node.nlp_data = node.model.nlp_data
end

function JuMP.set_objective(node::OptiNode,sense::MOI.OptimizationSense,ex::JuMP._NonlinearExprData)
    JuMP._init_NLP(node)
    JuMP.set_objective_sense(node, sense)
    node.nlp_data.nlobj = ex
    return
end

#NLP Data for nonliner objective function and (someday) nonlinear link constraints
function JuMP._init_NLP(graph::OptiGraph)
    error("An OptiGraph does not yet support the @NLconstraint macro.")
end

function JuMP._parse_NL_expr_runtime(graph::OptiGraph, x, tape, parent, values)
    error("An OptiGraph does not yet support the @NLconstraint macro.")
end

function JuMP.set_objective(node::OptiNode,sense::MathOptInterface.OptimizationSense,data::JuMP._NonlinearExprData)
    JuMP.set_objective(node.model,sense,data)
end


function JuMP._parse_NL_expr_runtime(node::OptiNode, x::Real, tape, parent, values)
    push!(values, x)
    push!(tape, JuMP.NodeData(JuMP.VALUE, length(values), parent))
    nothing
end

function JuMP._parse_NL_expr_runtime(node::OptiNode, x::JuMP.VariableRef, tape, parent, values)
    push!(tape, JuMP.NodeData(JuMP.MOIVARIABLE, x.index.value, parent))
    nothing
end

function JuMP._parse_NL_expr_runtime(node::OptiNode, x::NonlinearExpression, tape, parent, values)
    push!(tape, JuMP.NodeData(JuMP.SUBEXPRESSION, x.index, parent))
    nothing
end

function JuMP._parse_NL_expr_runtime(node::OptiNode, x::NonlinearParameter, tape, parent, values)
    push!(tape, JuMP.NodeData(JuMP.PARAMETER, x.index, parent))
    nothing
end

function JuMP._parse_NL_expr_runtime(node::OptiNode, x::AbstractArray, tape, parent, values)
    error("Unexpected array $x in nonlinear expression. Nonlinear expressions may contain only scalar expressions.")
end

function JuMP._parse_NL_expr_runtime(node::OptiNode, x::GenericQuadExpr, tape, parent, values)
    error("Unexpected quadratic expression $x in nonlinear expression. " *
          "Quadratic expressions (e.g., created using @expression) and " *
          "nonlinear expressions cannot be mixed.")
end

function JuMP._parse_NL_expr_runtime(node::OptiNode, x::GenericAffExpr, tape, parent, values)
    error("Unexpected affine expression $x in nonlinear expression. " *
          "Affine expressions (e.g., created using @expression) and " *
          "nonlinear expressions cannot be mixed.")
end

function JuMP._parse_NL_expr_runtime(node::OptiNode, x, tape, parent, values)
    error("Unexpected object $x (of type $(typeof(x)) in nonlinear expression.")
end

JuMP.name(cref::ConstraintRef{OptiNode,NonlinearConstraintIndex,ScalarShape}) = "Nonlinear reference"


#PRINTING
function JuMP._tape_to_expr(m::OptiNode, k, nd::Vector{JuMP.NodeData}, adj, const_values,
                      parameter_values, subexpressions::Vector{Any},
                      user_operators::JuMP._Derivatives.UserOperatorRegistry,
                      generic_variable_names::Bool, splat_subexpressions::Bool,
                      print_mode=REPLMode)
        return JuMP._tape_to_expr(Model(),k, nd, adj, const_values,
                              parameter_values, subexpressions,
                              user_operators,
                              generic_variable_names, splat_subexpressions,
                              print_mode)

end

#------------------------------------------------------------------------
## _NonlinearExprData
#------------------------------------------------------------------------
function JuMP.nl_expr_string(model::OptiNode, mode, c::JuMP._NonlinearExprData)
    return string(JuMP._tape_to_expr(model, 1, c.nd, JuMP.adjmat(c.nd), c.const_values,
                                [], [], model.nlp_data.user_operators, false,
                                false, mode))
end

#------------------------------------------------------------------------
## _NonlinearConstraint
#------------------------------------------------------------------------

function JuMP.nl_constraint_string(node::OptiNode, mode, c::JuMP._NonlinearConstraint)
    s = JuMP._sense(c)
    nl = JuMP.nl_expr_string(node.model, mode, c.terms)
    if s == :range
        out_str = "$(_string_round(c.lb)) " * _math_symbol(mode, :leq) *
                  " $nl " * _math_symbol(mode, :leq) * " " * _string_round(c.ub)
    else
        if s == :<=
            rel = JuMP._math_symbol(mode, :leq)
        elseif s == :>=
            rel = JuMP._math_symbol(mode, :geq)
        else
            rel = JuMP._math_symbol(mode, :eq)
        end
        out_str = string(nl, " ", rel, " ", JuMP._string_round(JuMP._rhs(c)))
    end
    return out_str
end

#TODO
const NonlinearLinkConstraintRef = ConstraintRef{OptiNode, NonlinearConstraintIndex}# where T <: OptiObject

function Base.show(io::IO, c::NonlinearLinkConstraintRef)
    print(io, JuMP.nl_constraint_string(c.model, REPLMode, c.model.nlp_data.nlconstr[c.index.value]))
end

function Base.show(io::IO, ::MIME"text/latex", c::NonlinearLinkConstraintRef)
    constraint = c.model.nlp_data.nlconstr[c.index.value]
    print(io, JuMP._wrap_in_math_mode(JuMP.nl_constraint_string(c.model, IJuliaMode, constraint)))
end


# function JuMP.set_objective(graph::OptiGraph,sense::MathOptInterface.OptimizationSense,data::JuMP._NonlinearExprData)
#     JuMP._init_NLP(graph)
#     JuMP.set_objective_sense(graph,sense)
#     graph.nlp_data.nlobj = data
# end

#TODO: Use a union for both optinode and optigraph when we implement nonlinear linking constraints
#const OptiObject = Union{OptiNode,OptiGraph}

#Functions copied from JuMP.jl.  These would be necessary to do nonlinear LinkConstraints
# function JuMP._parse_NL_expr_runtime(node::OptiObject, x::Real, tape, parent, values)
#     push!(values, x)
#     push!(tape, JuMP.NodeData(JuMP.VALUE, length(values), parent))
#     nothing
# end
#
# function JuMP._parse_NL_expr_runtime(node::OptiObject, x::JuMP.VariableRef, tape, parent, values)
#     push!(tape, JuMP.NodeData(JuMP.MOIVARIABLE, x.index.value, parent))
#     nothing
# end
#
# function JuMP._parse_NL_expr_runtime(node::OptiObject, x::NonlinearExpression, tape, parent, values)
#     push!(tape, JuMP.NodeData(JuMP.SUBEXPRESSION, x.index, parent))
#     nothing
# end
#
# function JuMP._parse_NL_expr_runtime(node::OptiObject, x::NonlinearParameter, tape, parent, values)
#     push!(tape, JuMP.NodeData(JuMP.PARAMETER, x.index, parent))
#     nothing
# end
#
# function JuMP._parse_NL_expr_runtime(node::OptiObject, x::AbstractArray, tape, parent, values)
#     error("Unexpected array $x in nonlinear expression. Nonlinear expressions may contain only scalar expressions.")
# end
#
# function JuMP._parse_NL_expr_runtime(node::OptiObject, x::GenericQuadExpr, tape, parent, values)
#     error("Unexpected quadratic expression $x in nonlinear expression. " *
#           "Quadratic expressions (e.g., created using @expression) and " *
#           "nonlinear expressions cannot be mixed.")
# end
#
# function JuMP._parse_NL_expr_runtime(node::OptiObject, x::GenericAffExpr, tape, parent, values)
#     error("Unexpected affine expression $x in nonlinear expression. " *
#           "Affine expressions (e.g., created using @expression) and " *
#           "nonlinear expressions cannot be mixed.")
# end
#
# function JuMP._parse_NL_expr_runtime(node::OptiObject, x, tape, parent, values)
#     error("Unexpected object $x (of type $(typeof(x)) in nonlinear expression.")
# end

# JuMP.constraint_object(ref::ConstraintRef{OptiNode,NonlinearConstraintIndex,ScalarShape}) = ref.model
# JuMP.name(cref::ConstraintRef{T,NonlinearConstraintIndex,ScalarShape} where T <: OptiObject) = "test"
# JuMP.constraint_object(ref::ConstraintRef{T,NonlinearConstraintIndex,ScalarShape} where T <: OptiObject) = ref.model
# JuMP.object_dictionary(m::OptiObject) = m.objdict
