require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def num_complete(list)
    list[:todos].count { |todo| todo[:completed] }
  end

  def complete?(list)
    list[:todos].size > 0 && list[:todos].all? { |todo| todo[:completed] }
  end

  def list_class(list)
    "complete" if complete?(list)
  end

  def sort_lists(lists)
    complete_lists, incomplete_lists = lists.partition { |list| complete?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# View a specific list
get "/lists/:idx" do
  @idx = params[:idx].to_i
  @list = session[:lists][@idx]
  erb :one_list, layout: :layout
end

# Render form for editing an existing list
get "/lists/:idx/edit" do
  @idx = params[:idx].to_i
  @list = session[:lists][@idx]
  erb :edit_list, layout: :layout
end

# Return an error message if the name is invalid.
# Otherwise, return nil.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Update an existing list
post "/lists/:idx" do
  list_name = params[:list_name].strip
  @idx = params[:idx].to_i

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    session[:lists][@idx][:name] = list_name
    session[:success] = "The list has been successfully edited."
    redirect "/lists/#{@idx}"
  end
end

# Delete a list
post "/lists/:idx/delete" do
  session[:lists].delete_at(params[:idx].to_i)
  session[:success] = "Deletion successful."
  redirect "/lists"
end

def error_for_todo_name(name, list)
  if !(1..100).cover? name.size
    "Todo name must be between 1 and 100 characters."
  end
end

# Add a todo to a list
post "/lists/:idx/add" do
  @idx = params[:idx].to_i
  @list = session[:lists][@idx]
  todo_name = params[:todo].strip

  error = error_for_todo_name(todo_name, @list)
  if error
    session[:error] = error
    erb :one_list, layout: :layout
  else 
    @list[:todos] << { name: todo_name, completed: false }
    session[:success] = "Todo added successfully."
    redirect "/lists/#{@idx}"
  end
end

# Delete a todo from a list
post "/lists/:idx/remove/:todo_idx" do
  @idx = params[:idx].to_i
  @list = session[:lists][@idx]

  todo_idx = params[:todo_idx].to_i
  @list[:todos].delete_at(todo_idx)
  session[:success] = "Todo deleted successfully."

  redirect "/lists/#{@idx}"
end

# Complete all todos on a list
post "/lists/:idx/complete_all" do
  @idx = params[:idx].to_i
  @list = session[:lists][@idx]

  @todos = @list[:todos]
  @todos.each { |todo| todo[:completed] = true }

  session[:success] = "All todos done!"
  redirect "/lists/#{@idx}"
end

# Update status of a todo
post "/lists/:idx/complete/:todo_idx" do
  @idx = params[:idx].to_i
  @list = session[:lists][@idx]
  @todos = @list[:todos]

  todo_idx = params[:todo_idx].to_i
  is_completed = params[:completed] == 'true'
  @todos[todo_idx][:completed] = is_completed

  session[:success] = "Todo updated successfully."
  redirect "/lists/#{@idx}"
end 

