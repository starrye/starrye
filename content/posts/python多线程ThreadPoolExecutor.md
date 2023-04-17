---
title: python多线程ThreadPoolExecutor
date: 2020-09-10T15:21:09+08:00
lastmod: 2020-09-10T15:21:09+08:00
author: 晚风
cover: /img/ThreadPoolExecutor.png
categories: 
  - python基础
tags: 
  - 多线程
# showcase: true
---

python多线程之ThreadPoolExecutor包解析

<!--more-->
<font size=4>线程池定义</font>
- 一种线程使用模式。线程过多会带来调度开销，进而影响缓存局部性和整体性能。而线程池维护着多个线程，等待着监督管理者分配可并发执行的任务。这避免了在处理短时间任务时创建与销毁线程的代价。线程池不仅能够保证内核的充分利用，还能防止过分调度。

<font size=4>ThreadPoolExecutor介绍</font>
- 包名:futures
- 在concurrent.future(py2,py3均有)模块中有ThreadPoolExecutor和ProcessPoolExecutor两个类，这两个类实现线程/进程池，只需短短几行就可以实现我们的目的。
- 线程池的基类是 concurrent.futures 模块中的 Executor，Executor 提供了两个子类，即 ThreadPoolExecutor 和 ProcessPoolExecutor，其中 ThreadPoolExecutor 用于创建线程池，而 ProcessPoolExecutor 用于创建进程池。

<font size=4>ThreadPoolExecutor源码分析</font>
{{< figure src="/img/ThreadPoolExecutor.png" width="90%" >}}

<font size=4>代码演示 </font>

---


	import time
    from concurrent.futures import ThreadPoolExecutor, wait, ALL_COMPLETED, as_completed, FIRST_COMPLETED
    
    # 测试函数
    def test(a):
        time.sleep(a)
        # print "test{}".format(a)
        return "result{}".format(a)
    
    
    # 创建线程池-最多可同时执行两个线程
    pool = ThreadPoolExecutor(max_workers=2)
    
    test_list = []
    # 利用submit提交任务，第一个参数为测试函数 第二个参数为函数所需要的参数,根据源码可知 此处的test_x是Future对象的实例
    # 所以他们可以调用future的方法
    test_1 = pool.submit(test, 1)
    test_list.append(test_1)
    test_2 = pool.submit(test, 2)
    test_list.append(test_2)
    test_3 = pool.submit(test, 3)
    test_list.append(test_3)
    test_4 = pool.submit(test, 4)
    test_list.append(test_4)
    
    
    print '----------wait-------------'
    # wait
    # 让主线程阻塞，直到满足设定的要求
    # ALL_COMPLETED(默认)：表明要等待所有的任务都结束。
    # FIRST_COMPLETED：当抛出第一个异常时等待结束，如果没有异常，等默认等待所有任务结束
    # FIRST_EXCEPTION：当任意一个任务完成或者被取消，则等待结束
    a = wait(test_list, return_when=FIRST_COMPLETED)
    print type(a)
    for i in a:
        print i.__str__()
    
    print '---------running-----------'
    # running用来判断任务是否正在运行(True/False)
    print "test_1 running:{}".format(test_1.running())  # 返回True
    print "test_3 running:{}".format(test_3.running())  # 返回False 因为线程池大小为2，test_3还在排队等候
    
    print '---------done--------------'
    # done用来判断任务是否结束(True/False)，隶属类Future的方法
    time.sleep(1)
    print "test_1 done:{}".format(test_1.done())  # 输出结果为True
    print "test_2 done:{}".format(test_2.done())  # 输出结果为False
    
    print '--------cancel-------------'
    # cancel用来取消线程任务。如果任务正在执行，不可取消，则该方法返回 False；否则，程序会取消该任务，并返回 True。
    print "test_3 cancel:{}".format(test_3.cancel())  # 返回False 因为线程池大小为2 任务test_3已经投入线程池运行了
    print "test_4 cancel:{}".format(test_4.cancel())  # 返回True 因为此时test4还在排队等候进入线程池
    
    print '-------cancelled-----------'
    # cancelled用来判断代表的线程任务是否被成功取消(True/False)
    print "test_3 cancelled:{}".format(test_3.cancelled())  # 返回False
    print "test_4 cancelled:{}".format(test_4.cancelled())  # 返回True
    
    print '--------result-------------'
    # result用来获取线程执行结果，隶属类Future的方法
    print "test_1 result:{}".format(test_1.result())  # 此方法当未设置timeout时会阻塞等待任务完成返回结果
    # print "test_2 result:{}".format(test_2.result(timeout=0.5))  # 结果会报错，因为设置了超时时间为0.5s 而此时test_2还需要1s才能完成任务
    
    print '-----add_done_callback-----'
    # add_done_callback回调函数，当线程任务完成后，程序会自动触发该回调函数，并将对应的 Future 对象作为参数传给该回调函数
    # 隶属于Future的方法，为了获取线程执行结果，与result类似但不阻塞等待
    # !:调用add_done_callback没有返回值，仅仅是执行回调函数，须注意。
    
    
    def callback(future):
        print "callback test{}".format(future.result())
    
    
    test_2.add_done_callback(callback)
    time.sleep(1)
    
    print '-------as_completed--------'
    # as_completed 用于获取任务列表里的任务执行结果
    # 隶属于future的方法
    # as_completed() 方法是一个生成器，
    # 在没有任务完成的时候，会阻塞，有任务完成就会弹出任务执行结果，然后继续循环，如果下一个任务还没执行完成仍然继续阻塞住，循环到所有的任务结束
    for task in as_completed(test_list):
        # 没有取消的任务才能获取执行结果，不然会报错CancelledError
        if not task.cancelled():
            print "get {} success!".format(task.result())
    
    
    print '-------shutdown------------'
    # shutdown用来关闭线程池，隶属类ThreadPoolExecutor的方法
    pool.shutdown()
 
