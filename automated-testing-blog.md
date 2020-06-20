

# Automated testing

Feb 21, 2016

[source](https://abelsiqueira.github.io/blog/automated-testing/)

We’re gonna learn how to make a test for your Julia code that runs whenever you publish it online. We’re gonna use

- [GitHub](http://github.com) to store the code;
- [Travis CI](http://travis-ci.com) to run your tests;
- [Coveralls.io](http://coveralls.io) to verify which lines of code your test are missing.

Alternatively, for a open source alternative, see [GitLab](http://gitlab.com), which I don’t know enough yet.

------

Let’s make a litte code to solve a linear system, paying attention to the problems it may arise, like incorrect dimensions, underdetermined and overdetermined systems, singular matrices, etc. And we’ll be using the factorizations, but not `\`.

## The math

A simple (not cheap) way to do it is using Singular Value Decomposition (SVD). We have

*A*=*U*Σ*V**T*=∑*i*=1*r**σ**i**u**i**v**T**i*.

where *r*

 is the rank of *A*. Since the columns of *V* form a basis for R*n* (where *x*

 resides), then

*x*=∑*j*=1*n**α**j**v**j*.

Now, we have

*A**x*=∑*i*=1*r*∑*j*=1*n**σ**i**α**j**u**i**v**T**i**v**j*=∑*i*=1*r**σ**i**α**i**u**i*

If the system has a solution, that is *A**x*=*b*

, then we multiply by *u**T**j*

, obtaining

*u**T**j**A**x*=∑*i*=1*r**σ**i**α**i**u**T**j**u**i*=*σ**j**α**j*=*u**T**j**b*

Thus, *α**j*=*u**T**j**b**σ**j*

. If the system doesn’t have a solution, this still holds. I’ll leave the steps to you.

If *r*<*n*

, then *α* has undetermined values. However, when that’s the case, the solution we’ll use is the one with the smallest norm, that is, the one that minimizes ∥*x*∥. Since *v**i* are orthonormal, then ∥*x*∥2=∑*n**i*=1*α*2*i*. So, in order to minimize the norm of x, we use *α**i*=0 for *i*>*r*

.

## The code

We’ll store the code on [this](http://github.com/abelsiqueira/BlogAutomatedTesting.jl) GitHub repository. Note, however, that it will point to the completed version.

A possible implementation of our code is as follows:

```julia
# File src/solve_linear.jl
function linear_system(A, b)
  (m,n) = size(A)
  if m != length(b)
    error("A and b are not compatible")
  end
  U, σ, V = svd(A)

  return V*(U'*b./σ)
end
```

To test it, open julia on the root folder and do

```julia
julia> A = rand(5,5); b = rand(5)
julia> include("src/solve_linear.jl")
julia> norm(linear_system(A,b) - A\b)
```

If the result is around $1 e^{−16} $ , then everything went well. Very rarely, the generated matrix could be ill-conditioned. Run again, to verify if that’s the case.

If everything went well, we’ll write a test now.

For now, let’s write a simple test running a lot of square linear systems. For each system, to avoid using `A\b`, we’ll create a vector `b` from a known solution. Then we’ll **assure** that ∥*A**x*−*b*∥<*ϵ*

and ∥*x*−*e*∥<*ϵ*. To do that, we’ll use `Base.Test`. Note however, that the condition of the matrix influences the error, and there are numerical errors involved. So we’ll use the condition ∥*x*−*e*∥<10−12*c**o**n**d*(*A*)

. The code is

```julia
# file test/test1.jl
srcroot = "$(dirname(@__FILE__))/../src"
include("$srcroot/solve_linear.jl")

using Base.Test

ϵ = 1e-12

for n = 10:10:100
  for T = 1:10
    A = rand(n,n); e = ones(n); b = A*e;
    x = linear_system(A, b)
    κ = cond(A)
    @test norm(x - e) < ϵ*κ
    @test norm(A*x - b) < ϵ*κ
  end
end
```

Run with

```
$ julia test/test1.jl
```

Nothing should appear.

The first line is a kludge to read the correct file from wherever the run the code. If you’re not building a module, this is ok. But normally you’ll want to build a module. Ignore that for now. The first for varies the dimension, and the second for runs the code a specific number of times. This totals a hundred square linear systems being run. The `@test` macro verifies that the given expression is true. If any solution is wrong, the code will be wrong. Also, if you use a smaller tolerance, the numerical rounding may give a error here.

Ok, first thing you wanna do now is commit this code.

```
$ git init
$ git add src test
$ git commit -m 'First commit'
```

Then, go to GitHub, create an account, then a repository for this code (e.g. linear_system.jl), then push the code. **Use the name with .jl in the end for the repository.**

```
$ git add origin http://link/to/your/github/repository/
$ git push -u origin master
```

Enter your password and verify the code is online.

## Online testing

Now go to Travis and create an account. Go to your profile and click on the `Sync account` button if necessary. Find your repository and set the button to on. Now, with the next commit, a test will start. Let’s make it happen.

Create a file `.travis.yml` (yes, with a leading dot) with information for the build. Here’s a simple file:

```
# file .travis.yml
language: julia

julia:
  - release
  - nightly

script:
  - julia test/test1.jl
```

Include the file and push

```
$ git add .travis.yml
$ git commit -m 'Add .travis.yml'
$ git push
```

Now, go to your travis page, and after a while you’ll see your repository with a test running (or already finished, because it is short). You should have a passing test. If not, verify your files again, then the error on travis. Notice that you can see the complete log of what is run.

Using an online automated testing is useful for many reasons:

- Everyone can see if the code is working;
- Pull requests generate a travis build, so you can see if it’s working;
- You don’t forget to test;
- You test on a clean environment;
- You can test with multiple versions of Julia (or other linguage).

## Coverage

Now, let’s see the code coverage. First, for coverage you’ll need a package to see the coverage, and the service to publish the coverage.

Use [Coverage.jl](https://github.com/JuliaCI/Coverage.jl) to see your coverage (including locally). Install with

```
julia> Pkg.add("Coverage")
```

Then run

```
$ julia --code-coverage=user --inline=no test/test1.jl
```

This will generate a file `src/solve_linear.jl.xxx.cov` with the information. The option `--inline=no` gives more accurate results, but slow down the code. You can see which function are not being run by reading it, but it’s better to see it online.

To see a summary, use

```
julia> using Coverage
julia> cov = process_folder()
julia> c, t = get_summary(cov)
julia> println("$(100c/t)% of lines covered")
```

But we want to see it online. So go to Coveralls.io and create an account. Click on `Add repos` and find you repository. Enable it, and change the `.travis.yml` file to

```
# file .travis.yml
language: julia

julia:
  - release
  - nightly

script:
  - julia --code-coverage=user --inline=no test/test1.jl

after_success:
  - julia -E 'Pkg.add("Coverage"); using Coverage; Coveralls.submit(process_folder())'
```

After a success, we install Coverage and run the relevant code. Check your repository on Coveralls to see the results. Notice how the `error` line on our code never gets called.

## Improving to a module

If you want people to use your code, you should use a module in Julia. This allows easy installation of your code, and not much more work. Changing to a module is very simple, so I’ll run through it. The folders `src` and `test` are required. But we also need

- A file in src with the same name as the repository;
- The keyword `module` on that file;
- `export` the relevant functions;
- A file `test/runtests.jl` that run the tests;
- A `README.md` for people to know about your thing;
- A `LICENSE.md` for people to know what they can do with your file;
- Different `.travis.yml`.

I’m using the name `BlogAutomatedTesting.jl`, so a create the file

```
# file src/BlogAutomatedTesting.jl
module BlogAutomatedTesting

include("solve_linear.jl")

end
```

I edit the file

```
# file src/solve_linear.jl
export linear_system

function linear_system(A, b)
  (m,n) = size(A)
  if m != length(b)
    error("A and b are not compatible")
  end
  U, σ, V = svd(A)

  return V*(U'*b./σ)
end
```

Then file

```
# file test/runtests.jl
include("test1.jl")
```

and

```
# file test/test1.jl
using Base.Test
using BlogAutomatedTesting

ϵ = 1e-12

for n = 10:10:100
  for T = 1:10
    A = rand(n,n); e = ones(n); b = A*e;
    x = linear_system(A, b)
    κ = cond(A)
    @test norm(x - e) < ϵ*κ
    @test norm(A*x - b) < ϵ*κ
  end
end
```

And create a `README.md`

```
# BlogAutomatedTesting.jl

This package was created from the tutorial on
[Abel Siqueira's blog](http://abelsiqueira.github.io//blog)
```

The `LICENSE.md` file is up which license you’ll choose. See [this site](https://abelsiqueira.github.io/blog/automated-testing/choosealicense.com) for options. Copy the contents to the file.

Now change `.travis.yml` to treat your code like a package.

```
# file .travis.yml
language: julia

julia:
  - release
  - nightly

install:
  - julia -E 'Pkg.clone(pwd())'

script:
  - julia -E 'Pkg.test("BlogAutomatedTesting"; coverage=true)'

after_success:
  - julia -E 'cd(Pkg.dir("BlogAutomatedTesting")); Pkg.add("Coverage"); using Coverage; Coveralls.submit(process_folder())'
```

Commit and verify your update on Travis and Coveralls

```
$ git add .
$ git commit -m 'Change to module'
$ git push
```

I hope this was helpful enough.