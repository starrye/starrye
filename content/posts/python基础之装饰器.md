---
title: python基础之装饰器
date: 2022-01-21T15:00:00+08:00
lastmod: 
author: 晚风
cover: "img/装饰器.jpeg"
categories: 
  - python基础
tags: 
  - python基础

---



python基础之装饰器

<!--more-->

## 1.简单装饰器

```
def zsq(func):
    def wrapper(*args, **kwargs):
        print('装饰器:让开,我要开始装逼了')
        func()  # 调用被装饰的函数
        print('装饰器:装逼完毕')
    #print(wrapper)
    return wrapper


@zsq  # = zsq(test)=wrapper 加载zsq函数 运行到return wrapper
def test():
    print("装饰函数:还有人敢挡住我装逼路线？")


test()  # 启动装饰器的wrapper函数

```

### 输出结果 

```
装饰器:让开,我要开始装逼了
装饰函数:还有人敢挡住我装逼路线？
装饰器:装逼完毕
```



## 2.wraps装饰器

```
"""
开发者在定义自己的装饰器时，应该用wraps对其做一些处理，来避免一些问题
"""


def zsq(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print('装饰器:让开,我要开始装逼了')
        func()
        print('装饰器:装逼完毕')
    return wrapper


@zsq
def test():
    print("装饰函数:还有人敢挡住我装逼路线？")


test()
```

### 输出结果

```
装饰器:让开,我要开始装逼了
装饰函数:还有人敢挡住我装逼路线？
装饰器:装逼完毕
```

## 3.被装饰的函数有参数

```
from functools import wraps
from typing import List


def zsq(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print('装饰器:让开,我要开始装逼了')

        print("args:{}, kwargs:{}".format(args, kwargs))
        result = func(*args, **kwargs)  # 这里的result是test函数里面return的值!

        print('装饰器:装逼完毕')
        return result + " year!"  # 这里才是test()的最终返回值 因为它在func()也就是test函数的执行之后

    return wrapper


@zsq
def test(args, kwargs):
    print("装饰函数:还有人敢挡住我装逼路线？")
    return args


a = test("i'm args", kwargs="i'm kwargs")
print(a)
```

### 输出结果

```
装饰器:让开,我要开始装逼了
args:("i'm args",), kwargs:{'kwargs': "i'm kwargs"}
装饰函数:还有人敢挡住我装逼路线？
装饰器:装逼完毕
i'm args year!
```

## 4.装饰器有参数

```
from functools import wraps
from typing import List


def out(*args, **kwargs):  # 装饰器外再包裹一层函数，用于接受装饰器参数
    # print(f"我是装饰器的参数:args:{args}, kwargs:{kwargs}")
    def zsq(func):
        print(f"我是装饰器的参数:args:{args}, kwargs:{kwargs}")

        @wraps(func)
        def wrapper():
            print('装饰器:让开,我要开始装逼了')
            func()
            print('装饰器:装逼完毕')

        return wrapper
    return zsq


@out("i'm args", name="i'm kwargs")  # 1/先执行out函数 返回zsq引用 2/@out==>@zsq===>zsq(func)=>wrapper 执行zsq函数 返回wrapper引用
def test():
    print("装饰函数:还有人敢挡住我装逼路线？")


# 执行这行之前已经加载了wraper函数，test执行进行wrapper函数
test()
```

### 输出结果

```
我是装饰器的参数:args:("i'm args",), kwargs:{'name': "i'm kwargs"}
装饰器:让开,我要开始装逼了
装饰函数:还有人敢挡住我装逼路线？
装饰器:装逼完毕
```

## 5.被装饰函数和装饰器都有参数

```
from functools import wraps


def out(*args, **kwargs):
    def zsq(func):
        print(f"我是装饰器的参数: args:{args}, kwargs:{kwargs}")

        @wraps(func)
        def wrapper(*args, **kwargs):
            print(f"我是函数的参数: args:{args}, kwargs:{kwargs}")

            print('装饰器:让开,我要开始装逼了')
            result = func(*args, **kwargs)
            print('装饰器:装逼完毕')

            return result + " year" # 在test函数执行完毕执行 然后返回最终值
        return wrapper
    return zsq


@out("装饰器的args", name="装饰器的kwargs")  # 执行zsq函数 同时打印装饰器的参数 然后加载wrapper函数
def test(args, **kwargs):
    print("装饰函数:还有人敢挡住我装逼路线？")
    return args


a = test("函数的args", name="函数的kwargs") # 执行wrapper函数 同时打印函数的参数 然后执行test函数
print(a)
```

### 输出结果

```
我是装饰器的参数: args:('装饰器的args',), kwargs:{'name': '装饰器的kwargs'}
我是函数的参数: args:('函数的args',), kwargs:{'name': '函数的kwargs'}
装饰器:让开,我要开始装逼了
装饰函数:还有人敢挡住我装逼路线？
装饰器:装逼完毕
函数的args year
```

## 6.类装饰器

```
# 不带参数的装饰器
class Zsq(object):
    def __init__(self, func):
        self.func = func

    def __call__(self, *args, **kwargs):
        print(f"我是函数的参数: args:{args}, kwargs:{kwargs}")

        print('装饰器:让开,我要开始装逼了')
        self.func(*args, **kwargs)
        print('装饰器:装逼完毕')


# @Zsq
# def test(args, **kwargs):
#     print("装饰函数:还有人敢挡住我函数的装逼路线？")
#
#
# test("函数的args", name="函数的kwargs")


"""
         不带参数的装饰器    带参数的装饰器
__init__:接收被装饰函数     接收装饰器参数
__call__:接收函数的参数     接收被装饰函数同时增加装饰逻辑
"""


# 带参数的装饰器
class Zsq(object):
    def __init__(self, *args, **kwargs):
        print(f"我是装饰器的参数: args:{args}, kwargs:{kwargs}")

    def __call__(self, func):
        def wrapper(*args, **kwargs):
            print(f"我是函数的参数: args:{args}, kwargs:{kwargs}")

            print('装饰器:让开,我要开始装逼了')
            result = func(*args, **kwargs)
            print('装饰器:装逼完毕')

            return result + " year"
        return wrapper


@Zsq("装饰器的args", name="装饰器的kwargs")
def test(args, **kwargs):
    print("装饰函数:还有人敢挡住我装逼路线？")
    return args


a = test("函数的args", name="函数的kwargs")
print(a)
```

### 输出结果

```
我是装饰器的参数: args:('装饰器的args',), kwargs:{'name': '装饰器的kwargs'}
我是函数的参数: args:('函数的args',), kwargs:{'name': '函数的kwargs'}
装饰器:让开,我要开始装逼了
装饰函数:还有人敢挡住我装逼路线？
装饰器:装逼完毕
函数的args year
```

## 7.多装饰器同时装饰一个函数

```
from functools import wraps

"""
多装饰器同时装饰一个函数：可以想像进栈操作，先进后出 进的时候输出一下(先进先输出)  出的时候输出一下(后进先输出)
"""

def zsq1(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print('1装饰器:让开,我要开始装逼了')
        func()
        print('1装饰器:装逼完毕')

    return wrapper


def zsq2(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        print('2装饰器:让开,我要开始装逼了')
        func()
        print('2装饰器:装逼完毕')

    return wrapper


@zsq1
@zsq2
def test():
    print("装饰函数:还有人敢挡住我装逼路线？")


test()
```

### 输出结果

```
1装饰器:让开,我要开始装逼了
2装饰器:让开,我要开始装逼了
装饰函数:还有人敢挡住我装逼路线？
2装饰器:装逼完毕
1装饰器:装逼完毕
```



